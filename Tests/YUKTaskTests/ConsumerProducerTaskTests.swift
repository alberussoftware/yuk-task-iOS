//
//  ConsumerProducerTaskTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/4/21.
//

import XCTest
import Combine
@testable import YUKTask

// MARK: -
final class ConsumerProducerTaskTests: XCTestCase {
  func testExecute() {
    final class ProducingTestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
    }
    final class TestTask: ConsumerProducerTask<Int, Int, Error> {
      override func execute(with consumed: Consumed?) -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            switch consumed {
            case let .success(value):
              promise(.success(value + 21))
            default:
              XCTAssertTrue(false)
            }
          }
        }.eraseToAnyPublisher()
      }
    }
    
    let expectation = XCTestExpectation()
    var cancellables = [AnyCancellable]()
    let task1 = ProducingTestTask()
    let task2 = TestTask(producing: task1)
    
    task2.publisher
      .subscribe(on: Self.deliverDispatchQueue)
      .receive(on: DispatchQueue.main)
      .sink {
        switch $0 {
        case .finished:
          expectation.fulfill()
        default:
          XCTAssertTrue(false)
        }
      } receiveValue: {
        XCTAssert($0 == 42)
      }
      .store(in: &cancellables)
    
    Self.taskQueue.add(task1)
    Self.taskQueue.add(task2)
    
    wait(for: [expectation], timeout: 5.0)
  }
  func testProducingCancellation() {
    final class ProducingTestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            guard !self.isCancelled else {
              promise(.failure(.cancelled))
              return
            }
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
    }
    final class TestTask: ConsumerProducerTask<Int, Int, Error> {
      override func execute(with consumed: Consumed?) -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            switch consumed {
            case .failure(.cancelled):
              promise(.failure(.cancelled))
            default:
              XCTAssertTrue(false)
            }
          }
        }.eraseToAnyPublisher()
      }
    }
    
    let expectation = XCTestExpectation()
    var cancellables = [AnyCancellable]()
    let task1 = ProducingTestTask()
    let task2 = TestTask(producing: task1)
    task2.publisher
      .subscribe(on: Self.deliverDispatchQueue)
      .receive(on: DispatchQueue.main)
      .sink {
        switch $0 {
        case .failure(.cancelled):
          expectation.fulfill()
        default:
          XCTAssertTrue(false)
        }
      } receiveValue: { (_) in
        XCTAssertTrue(false)
      }
      .store(in: &cancellables)
    
    Self.taskQueue.add(task1)
    Self.taskQueue.add(task2)
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      task1.cancel()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  static var allTests = [
    ("testExecute", testExecute),
    ("testProducingCancellation", testProducingCancellation),
  ]
}

