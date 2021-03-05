//
//  GroupProducerTaskTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/14/21.
//

import XCTest
import Combine
@testable import YUKTask

import struct CoreLocation.CLLocationCoordinate2D

// MARK: -
final class GroupProducerTaskTests: XCTestCase {
  func test() {
    var cancellables = [AnyCancellable]()
    let expectation1 = XCTestExpectation()
    let task1 = BlockProducerTask<Int, Error> { (_) in
      Future { (promise) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
          expectation1.fulfill()
          promise(.success(21))
        }
      }.eraseToAnyPublisher()
    }
    let expectation2 = XCTestExpectation()
    let task2 = BlockConsumerProducerTask<Int,Int, Error>(producing: task1) { (_, consumed) in
      Future { (promise) in
        guard let consumed = consumed else {
          promise(.failure(.cancelled))
          return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
          expectation2.fulfill()
          promise(consumed.map { $0 * 2})
        }
      }.eraseToAnyPublisher()
    }
    let expectation3 = XCTestExpectation()
    let producer = BlockConsumerProducerTask<Int, Int, Error>(producing: task2) { (_, consumed) in
      Future { (promise) in
        guard let consumed = consumed else {
          promise(.failure(.cancelled))
          return
        }
        dispatchPrecondition(condition: .onQueue(Self.workDispatchQueue))
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
          expectation3.fulfill()
          promise(consumed.map { $0 * 2})
        }
      }.eraseToAnyPublisher()
    }
    let expectation4 = XCTestExpectation()
    let groupTask = GroupProducerTask<Int, Error>({
      task1
      task2
    }, producer: producer)
    groupTask.publisher
      .subscribe(on: Self.deliverDispatchQueue)
      .receive(on: Self.deliverDispatchQueue)
      .sink {
        switch $0 {
        case .finished:
          expectation4.fulfill()
        default:
          XCTAssertTrue(false)
        }
      } receiveValue: {
        XCTAssert($0 == 84)
      }
      .store(in: &cancellables)
    Self.taskQueue.add(groupTask)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 7.0, enforceOrder: true)
  }
  func testConditions() {
    struct TestCondition: Condition {
      typealias Failure = Never
      
      func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
        NonFailBlockTask { (_) in
          Future { (promise) in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
              dependencyExpectation.fulfill()
              promise(.success)
            }
          }.eraseToAnyPublisher()
        }.eraseToAnyProducerTask()
      }
      
      func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Never> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            evaluateExpectation.fulfill()
            promise(.success)
          }
        }.eraseToAnyPublisher()
      }
      
      private let dependencyExpectation: XCTestExpectation
      private let evaluateExpectation: XCTestExpectation
      init(dependencyExpectation: XCTestExpectation, evaluateExpectation: XCTestExpectation) {
        self.dependencyExpectation = dependencyExpectation
        self.evaluateExpectation = evaluateExpectation
      }
    }
    final class TestGroupProducerTask: NonFailGroupProducerTask<Int> {
      init(expectations: [XCTestExpectation]) {
        super.init()
        
        let innerTask1 = NonFailBlockTask { [weak self] (_) in
          Future { (promise) in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
              self?.produce(new: NonFailBlockTask { (_) in
                Future { (promise) in
                  DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                    promise(.success)
                    expectations[3].fulfill()
                  }
                }.eraseToAnyPublisher()
              })
              promise(.success)
              expectations[2].fulfill()
            }
          }.eraseToAnyPublisher()
        }
        innerTask1.add(condition: TestCondition(dependencyExpectation: expectations[0], evaluateExpectation: expectations[1]))
        add(inner: innerTask1)
        
        let innerTask2 = NonFailBlockTask { [weak self] (_) in
          Future { (promise) in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
              self?.produce(new: NonFailBlockTask { (_) in
                Future { (promise) in
                  DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                    promise(.success)
                    expectations[7].fulfill()
                  }
                }.eraseToAnyPublisher()
              })
              promise(.success)
              expectations[6].fulfill()
            }
          }.eraseToAnyPublisher()
        }
        innerTask2.add(condition: TestCondition(dependencyExpectation: expectations[4], evaluateExpectation: expectations[5]))
        innerTask2.add(dependency: innerTask1)
        add(inner: innerTask2)
        
        set(producer: NonFailBlockProducerTask { (_) in
          Future { (promise) in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
              promise(.success(21))
              expectations[8].fulfill()
            }
          }.eraseToAnyPublisher()
        })
      }
    }
    
    var cancellables = Set<AnyCancellable>()
    let expectations = (0...8).map { (_) in XCTestExpectation() }
    let finalExpectation = XCTestExpectation()
    let startTime = ProcessInfo.processInfo.systemUptime
    Self.taskQueue
      .add(TestGroupProducerTask(expectations: expectations))
      .sink {
        finalExpectation.fulfill()
        XCTAssert($0 == 21)
      }
      .store(in: &cancellables)
    
    wait(for: expectations + CollectionOfOne(finalExpectation), timeout: 15.0, enforceOrder: true)
    let diffTime = ProcessInfo.processInfo.systemUptime - startTime
    XCTAssert(14...15 ~= diffTime)
  }
  func testInRealCase() {
    let expectation = XCTestExpectation()
    var cancellable = Set<AnyCancellable>()
    let session: URLSession = {
      $0.networkServiceType = .responsiveData
      $0.waitsForConnectivity = true
      $0.tlsMinimumSupportedProtocolVersion = .TLSv13
      $0.urlCache = URLCache.shared
      $0.requestCachePolicy = .useProtocolCachePolicy
      return .init(configuration: $0)
    }(URLSessionConfiguration.default)
    Self.taskQueue
      .add(TestGroupTask(input: "KFC", session: session, sessionToken: UUID().uuidString))
      .sink {
        switch $0 {
        case let .failure(error):
          print(error)
        case .finished:
          expectation.fulfill()
        }
      } receiveValue: {
        print($0)
      }
      .store(in: &cancellable)
    
    wait(for: [expectation], timeout: 2.0)
  }
  
  static var allTests = [
    ("test", test),
    ("testConditions", testConditions),
    ("testInRealCase", testInRealCase),
  ]
}

// MARK: -
final class TestGroupTask: GroupProducerTask<[(SearchResultPoints.Entry, CLLocationCoordinate2D)], GoogleApiEndpoint.Error> {
  let input: String
  let sessionToken: String
  private let session: URLSession
  
  init(input: String, session: URLSession, sessionToken: String) {
    self.input = input
    self.session = session
    self.sessionToken = sessionToken
    super.init()
    
    let t1 = BlockProducerTask<[SearchResultPoints.Entry], GoogleApiEndpoint.Error> { (task) in
      guard !task.isCancelled else { return Fail(error: .apiError(.unknown)).eraseToAnyPublisher() }
      let placeAutocompleteLocation = CLLocationCoordinate2D(latitude: 41.311200, longitude: 69.279788)
      guard let placeAutocompleRequest = GoogleApiEndpoint.placeAutocomplete(forInput: input, withSessiontoken: sessionToken, on: placeAutocompleteLocation, limitByRadius: 12500).urlRequest else { preconditionFailure() }
      let placeAutocompleTask = URLRequestProducerDataTask(placeAutocompleRequest, session: self.session, sessionDataTaskPriority: URLSessionTask.highPriority)
      let decoder: JSONDecoder = { $0.keyDecodingStrategy = .convertFromSnakeCase; return $0 }(JSONDecoder())
      return self.produce(new: placeAutocompleTask)
        .decode(type: SearchResultPoints.self, decoder: decoder)
        .map { $0.entries }
        .mapError { (error) -> GoogleApiEndpoint.Error in
          switch error {
          case let error as DecodingError:
            return .decodingError(error)
          case let error as URLRequestProducerDataTask.Error:
            return .urlRequestError(error)
          case let error as GoogleApiEndpoint.Error.ApiError:
            return .apiError(error)
          default:
            return .apiError(.unknown)
          }
        }
        .eraseToAnyPublisher()
    }
    let t2 = BlockConsumerProducerTask<[SearchResultPoints.Entry], [(SearchResultPoints.Entry, CLLocationCoordinate2D)], GoogleApiEndpoint.Error>(producing: t1) { (task, cosumed) in
      guard !task.isCancelled else { return Fail(error: .apiError(.unknown)).eraseToAnyPublisher() }
      guard let cosumed = cosumed else { return Fail(error: GoogleApiEndpoint.Error.apiError(.unknown)).eraseToAnyPublisher() }
      switch cosumed {
      case let .success(entries):
        return Publishers.MergeMany(entries.lazy.map { (entry) -> AnyPublisher<(SearchResultPoints.Entry, CLLocationCoordinate2D), GoogleApiEndpoint.Error> in
          guard let placeDetailsRequest = GoogleApiEndpoint.placeDetails(forPlaceId: entry.placeId, withSessiontoken: sessionToken).urlRequest else { preconditionFailure() }
          let placeDetailsTask = URLRequestProducerDataTask(placeDetailsRequest, session: self.session, sessionDataTaskPriority: URLSessionTask.highPriority)
          let decoder: JSONDecoder = { $0.keyDecodingStrategy = .convertFromSnakeCase; return $0 }(JSONDecoder())
          return self.produce(new: placeDetailsTask)
            .decode(type: SearchResultPointLocation.self, decoder: decoder)
            .map { (entry, $0.location) }
            .mapError { (error) -> GoogleApiEndpoint.Error in
              switch error {
              case let error as DecodingError:
                return .decodingError(error)
              case let error as URLRequestProducerDataTask.Error:
                return .urlRequestError(error)
              case let error as GoogleApiEndpoint.Error.ApiError:
                return .apiError(error)
              default:
                return .apiError(.unknown)
              }
            }
            .eraseToAnyPublisher()
        })
        .collect()
        .eraseToAnyPublisher()
      case let .failure(error):
        return Fail(error: error).eraseToAnyPublisher()
      }
    }
    add(inner: t1)
    set(producer: t2)
  }
}

// MARK: -
final class URLRequestProducerDataTask: ProducerTask<Data, URLRequestProducerDataTask.Error> {
  let request: URLRequest
  let session: URLSession
  let sessionDataTaskPriority: Float
  private var sessionDataTask: URLSessionDataTask?
  
  override func execute() -> AnyPublisher<Data, Error> {
    guard !isCancelled else { return Fail(error: .cancelled).eraseToAnyPublisher() }
    return Future { [weak self] (promise) in
      guard let request = self?.request else {
        promise(.failure(.unknownFailure))
        return
      }
      self?.sessionDataTask = self?.session.dataTask(with: request) { (data, response, error) in
        if let error = error {
          promise(.failure(.clientFailure(error)))
          return
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse = httpResponse, !(200...299 ~= httpResponse.statusCode) {
          promise(.failure(.serverFailure(httpResponse)))
          return
        }
        
        if let mimeType = httpResponse!.mimeType, mimeType != "application/json" {
          promise(.failure(.incorrectMimeType(mimeType)))
          return
        }
        
        guard let data = data else {
          promise(.failure(.unknownFailure))
          return
        }
        
        promise(.success(data))
      }
      self?.sessionDataTask?.priority = self?.sessionDataTaskPriority ?? URLSessionTask.defaultPriority
      self?.sessionDataTask?.resume()
    }.eraseToAnyPublisher()
  }
  override func cancel() {
    sessionDataTask?.cancel()
    super.cancel()
  }
  
  init(_ request: URLRequest, session: URLSession = .shared, sessionDataTaskPriority: Float = URLSessionTask.defaultPriority) {
    self.request = request
    self.session = session
    self.sessionDataTaskPriority = sessionDataTaskPriority
    super.init()
  }
}
extension URLRequestProducerDataTask {
  enum Error: Swift.Error {
    case cancelled
    case clientFailure(Swift.Error)
    case serverFailure(HTTPURLResponse)
    case incorrectMimeType(String)
    case unknownFailure
  }
}

// MARK: -
struct GoogleApiEndpoint {
  static let key = "YOUR_GOOGLE_API_TOKEN"
  
  static func placeAutocomplete(forInput input: String, withSessiontoken sessiontoken: String, on location: CLLocationCoordinate2D, limitByRadius radius: Int) -> Self {
    .init(
      path: "/maps/api/place/autocomplete/json",
      queryItems: [
        .init(name: "input", value: input),
        .init(name: "sessiontoken", value: sessiontoken),
        .init(name: "location", value: "\(location.latitude),\(location.longitude)"),
        .init(name: "radius", value: "\(radius)"),
        .init(name: "strictbounds", value: nil),
        .init(name: "language", value: "ru"),
        .init(name: "key", value: Self.key)
      ]
    )
  }
  static func placeDetails(forPlaceId placeId: String, withSessiontoken sessiontoken: String, includes fields: [PlaceDetailsField] = PlaceDetailsField.allCases) -> Self {
    .init(
      path: "/maps/api/place/details/json",
      queryItems: [
        .init(name: "place_id", value: placeId),
        .init(name: "sessiontoken", value: sessiontoken),
        .init(name: "fields", value: .init(fields.reduce("", { $0 + $1.rawValue + "," }).dropLast(1))),
        .init(name: "language", value: "ru"),
        .init(name: "key", value: Self.key)
      ]
    )
  }
  static func reverseGeocode(for location: CLLocationCoordinate2D) -> Self {
    .init(
      path: "/maps/api/geocode/json",
      queryItems: [
        .init(name: "latlng", value: "\(location.latitude),\(location.longitude)"),
        .init(name: "result_type", value: "street_address"),
        .init(name: "language", value: "ru"),
        .init(name: "key", value: Self.key)
      ]
    )
  }
  
  let path: String
  let queryItems: [URLQueryItem]
  var urlRequest: URLRequest? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "maps.googleapis.com"
    components.path = path
    components.queryItems = queryItems
    guard let url = components.url else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    return request
  }
}
extension GoogleApiEndpoint {
  enum PlaceDetailsField: String, CaseIterable {
    case addressComponent = "address_component"
    case name
    case geometry
  }
}
extension GoogleApiEndpoint {
  enum Error: Swift.Error {
    case urlRequestError(URLRequestProducerDataTask.Error)
    case decodingError(DecodingError)
    case apiError(ApiError)
    
    enum ApiError: String, Swift.Error {
      case zeroResults = "ZERO_RESULTS"
      case overQueryLimit = "OVER_QUERY_LIMIT"
      case requestDenied = "REQUEST_DENIED"
      case invalidRequest = "INVALID_REQUEST"
      case notFound = "NOT_FOUND"
      case unknown = "UNKNOWN_ERROR"
      
      init(status: String) {
        switch status {
        case "ZERO_RESULTS":
          self = .zeroResults
        case "OVER_QUERY_LIMIT":
          self = .overQueryLimit
        case "REQUEST_DENIED":
          self = .requestDenied
        case "INVALID_REQUEST":
          self = .invalidRequest
        case "NOT_FOUND":
          self = .notFound
        case "UNKNOWN_ERROR":
          self = .unknown
        default:
          self = .unknown
        }
      }
    }
  }
}

// MARK: -
struct SearchResultPoints: Decodable {
  private enum CodingKeys: String, CodingKey {
    case entries = "predictions"
    case status
    case errorMessage
  }
  
  struct Entry: Decodable {
    private enum CodingKeys: String, CodingKey {
      case placeId
      case structuredFormatting
      
      case firstPartOfAddress = "mainText"
      case secondPartOfAdderess = "secondaryText"
      case matchedSubstringRange = "mainTextMatchedSubstrings"
      
      case length
      case offset
    }
    
    let placeId: String
    let firstPartOfAddress: String
    let secondPartOfAdderess: String
    let matchedSubstringRange: Range<String.Index>
    
    init(from decoder: Decoder) throws {
      let mainContainer = try decoder.container(keyedBy: CodingKeys.self)
      placeId = try mainContainer.decode(String.self, forKey: .placeId)
      
      let structuredFormattingContainer = try mainContainer.nestedContainer(keyedBy: CodingKeys.self , forKey: .structuredFormatting)
      firstPartOfAddress = try structuredFormattingContainer.decode(String.self, forKey: .firstPartOfAddress)
      secondPartOfAdderess = try structuredFormattingContainer.decode(String.self, forKey: .secondPartOfAdderess)
      
      var mainTextMatchedSubstringsUnkeyedContainer = try structuredFormattingContainer.nestedUnkeyedContainer(forKey: .matchedSubstringRange)
      
      let firstMainTextMatchedSubstringContainer = try mainTextMatchedSubstringsUnkeyedContainer.nestedContainer(keyedBy: CodingKeys.self)
      
      let length = try firstMainTextMatchedSubstringContainer.decode(Int.self, forKey: .length)
      let offset = try firstMainTextMatchedSubstringContainer.decode(Int.self, forKey: .offset)
      
      let leftBoundIndex = firstPartOfAddress.index(firstPartOfAddress.startIndex, offsetBy: offset)
      let rightBoundIndex = firstPartOfAddress.index(leftBoundIndex, offsetBy: length)
      matchedSubstringRange = leftBoundIndex..<rightBoundIndex
    }
  }
  
  let entries: [Entry]
  let status: String
  let errorMessage: String?
  
  init(from decoder: Decoder) throws {
    let mainContainer = try decoder.container(keyedBy: CodingKeys.self)
    status = try mainContainer.decode(String.self, forKey: .status)
    errorMessage = try? mainContainer.decode(String.self, forKey: .errorMessage)
    
    guard var entriesContainer = try? mainContainer.nestedUnkeyedContainer(forKey: .entries) else {
      entries = []
      return
    }
    
    var entries = [Entry]()
    entries.reserveCapacity(entriesContainer.count ?? 0)
    while !entriesContainer.isAtEnd { entries.append(try entriesContainer.decode(Entry.self)) }
    self.entries = entries
  }
}

// MARK: -
struct SearchResultPointLocation: Decodable {
  private enum CodingKeys: String, CodingKey {
    case result
    case status
    case errorMessage
    
    case geometry
    
    case location
    
    case lat
    case lng
  }
  
  let location: CLLocationCoordinate2D
  let status: String
  let errorMessage: String?
  
  init(from decoder: Decoder) throws {
    let mainContainer = try decoder.container(keyedBy: CodingKeys.self)
    status = try mainContainer.decode(String.self, forKey: .status)
    errorMessage = try? mainContainer.decode(String.self, forKey: .errorMessage)
    
    let locationContainer = try mainContainer
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .result)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .geometry)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .location)
    
    location = .init(latitude: try locationContainer.decode(Double.self, forKey: .lat), longitude: try locationContainer.decode(Double.self, forKey: .lng))
  }
}
