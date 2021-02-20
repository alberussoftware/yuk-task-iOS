//
//  GroupConsumerProducerTaskTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/17/21.
//

import XCTest
@testable import YUKTask

import class Combine.AnyCancellable

// MARk: -
final class GroupConsumerProducerTaskTests: XCTestCase {
  func test() {
    var cancellables = [AnyCancellable]()
    let expectation1 = XCTestExpectation()
    let producing = BlockProducerTask<Int, Error> { (_, promise) in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        expectation1.fulfill()
        promise(.success(21))
      }
    }
    let expectation2 = XCTestExpectation()
    let task2 = BlockConsumerProducerTask<Int,Int, Error>(producing: producing) { (_, consumed, promise) in
      guard let consumed = consumed else {
        promise(.failure(.cancelled))
        return
      }
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        expectation2.fulfill()
        promise(consumed.map { $0 * 2})
      }
    }
    let expectation3 = XCTestExpectation()
    let producer = BlockConsumerProducerTask<Int, Int, Error>(producing: task2) { (_, consumed, promise) in
      guard let consumed = consumed else {
        promise(.failure(.cancelled))
        return
      }
      dispatchPrecondition(condition: .onQueue(Self.workDispatchQueue))
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        expectation3.fulfill()
        promise(consumed.map { $0 * 2})
      }
    }
    let expectation4 = XCTestExpectation()
    let groupTask = GroupConsumerProducerTask<Int, Int, Error>(producing: producing, { task2 }, producer: producer)
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
    
    Self.taskQueue.add(producing)
    Self.taskQueue.add(groupTask)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 7.0, enforceOrder: true)
  }
  
  static var allTests = [
    ("test", test),
  ]
}
