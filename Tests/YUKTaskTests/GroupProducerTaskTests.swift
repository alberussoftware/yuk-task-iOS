//
//  GroupProducerTaskTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/14/21.
//

import XCTest
import Combine
@testable import YUKTask

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
  
  static var allTests = [
    ("test", test),
  ]
}
