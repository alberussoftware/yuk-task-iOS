//
//  ProducerTaskTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/4/21.
//

import XCTest
import Combine
@testable import YUKTask

// MARK: -
internal final class ProducerTaskTests: XCTestCase {
  // MARK: Internal Static Props
  internal static var allTests = [("testName", testName),
                                  ("testQualityOfService", testQualityOfService),
                                  ("testQueuePriority", testQueuePriority),
                                  
                                  ("testProduced", testProduced),
                                  
                                  ("testPublisher", testPublisher),
                                  
                                  ("testFinishes", testFinishes),
                                  ("testCancellation", testCancellation),
                                  ("testProduce", testProduce),
                                  
                                  ("testAddObserver", testAddObserver),
                                  ("testAddCondition", testAddCondition),
                                  
                                  ("testQueues", testQueues)]
  
  // MARK: Internal Methods
  internal func testName() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
    }
    
    let task = TestTask().name(#function)
    XCTAssert(task.name == #function)
    Self.taskQueue.add(task)
    Self.taskQueue.waitUntilAllTasksAreFinished()
    XCTAssert(task.name == #function)
  }
  internal func testQualityOfService() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
    }
    
    let task = TestTask().qualityOfService(.utility)
    XCTAssert(task.qualityOfService == .utility)
    Self.taskQueue.add(task)
    Self.taskQueue.waitUntilAllTasksAreFinished()
    XCTAssert(task.qualityOfService == .utility)
  }
  internal func testQueuePriority() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
    }
    
    let task = TestTask().queuePriority(.low)
    XCTAssert(task.queuePriority == .low)
    Self.taskQueue.add(task)
    Self.taskQueue.waitUntilAllTasksAreFinished()
    XCTAssert(task.queuePriority == .low)
  }
  //
  internal func testProduced() {
    final class SuccessTestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
    }
    final class FailureTestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Fail<Int, Error>(error: .oops).eraseToAnyPublisher()
      }
    }
    
    let task1 = SuccessTestTask()
    let task2 = FailureTestTask()
    Self.taskQueue.add(task1)
    Self.taskQueue.add(task2)
    Self.taskQueue.waitUntilAllTasksAreFinished()
    switch (task1.produced, task2.produced) {
    case (let .success(value), let .failure(error)):
      XCTAssert(value == 21 && error == .oops)
    default:
      XCTAssertTrue(false)
    }
  }
  //
  internal func testPublisher() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
    }
    
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    var cancellables = [AnyCancellable]()
    let task = TestTask()
    task.publisher
      .sink {
        switch $0 {
        case .failure:
          XCTAssertTrue(false)
        default:
          break
        }
        expectation2.fulfill()
      } receiveValue: {
        XCTAssert($0 == 21)
        expectation1.fulfill()
      }
      .store(in: &cancellables)
    Self.taskQueue.add(task)
    
    wait(for: [expectation1, expectation2], timeout: 3.0, enforceOrder: true)
  }
  //
  internal func testFinishes() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
      override func finishing(with produced: Produced) -> AnyPublisher<Void, Never> {
        switch produced {
        case let .success(value):
          XCTAssert(value == 21)
        default:
          XCTAssertTrue(false)
        }
        XCTAssertFalse(isFinished)
        finishingExpectation.fulfill()
        
        return Just(()).eraseToAnyPublisher()
      }
      override func finished(with produced: Produced) {
        switch produced {
        case let .success(value):
          XCTAssert(value == 21)
        default:
          XCTAssertTrue(false)
        }
        XCTAssertTrue(isFinished)
        finishedExpectation.fulfill()
      }
      
      private let finishingExpectation: XCTestExpectation
      private let finishedExpectation: XCTestExpectation
      init(_ finishingExpectation: XCTestExpectation, _ finishedExpectation: XCTestExpectation) {
        self.finishingExpectation = finishingExpectation
        self.finishedExpectation = finishedExpectation
      }
    }
    
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    let task = TestTask(expectation1, expectation2)
    Self.taskQueue.add(task)
    
    wait(for: [expectation1, expectation2], timeout: 3.0, enforceOrder: true)
  }
  internal func testCancellation() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        guard !isCancelled else {
          return Result.Publisher(.failure(.cancelled)).eraseToAnyPublisher()
        }
        XCTAssertTrue(false)
        return Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
    }
    let task = TestTask()
    Self.taskQueue.add(task)
    task.cancel()
    Self.taskQueue.waitUntilAllTasksAreFinished()
    switch task.produced {
    case .failure(.cancelled):
      XCTAssertTrue(true)
    default:
      XCTAssertTrue(false)
    }
  }
  internal func testProduce() {
    final class ProduceTestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(22))
          }
        }.eraseToAnyPublisher()
      }
    }
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        produce(new: produceTask)
        return Result.Publisher(.success(21)).eraseToAnyPublisher()
      }
      
      private let produceTask: ProduceTestTask
      init(_ produceTask: ProduceTestTask) {
        self.produceTask = produceTask
      }
    }
    
    let produceTask = ProduceTestTask()
    let task = TestTask(produceTask)
    
    Self.taskQueue.add(task)
    Self.taskQueue.waitUntilAllTasksAreFinished()
    
    switch produceTask.produced {
    case let .success(value):
      XCTAssert(value == 22)
    default:
      XCTAssertTrue(false)
    }
  }
  //
  internal func testAddObserver() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
    }
    struct TestObserver: Observer {
      func taskDidStart<O, F: Swift.Error>(_ task: ProducerTask<O, F>) {
        expectation2.fulfill()
      }
      func task<O1, F1: Swift.Error, O2, F2: Swift.Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>) {
        expectation1.fulfill()
      }
      func taskDidCancel<O, F: Swift.Error>(_ task: ProducerTask<O, F>) {
        expectation3.fulfill()
      }
      func taskDidFinish<O, F: Swift.Error>(_ task: ProducerTask<O, F>) {
        expectation4.fulfill()
      }
      
      private let expectation1: XCTestExpectation
      private let expectation2: XCTestExpectation
      private let expectation3: XCTestExpectation
      private let expectation4: XCTestExpectation
      init(_ expectation1: XCTestExpectation, _ expectation2: XCTestExpectation, _ expectation3: XCTestExpectation, _ expectation4: XCTestExpectation) {
        self.expectation1 = expectation1
        self.expectation2 = expectation2
        self.expectation3 = expectation3
        self.expectation4 = expectation4
      }
    }
    
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    let expectation3 = XCTestExpectation()
    let expectation4 = XCTestExpectation()
    let task = TestTask()
    let observer = TestObserver(expectation1, expectation2, expectation3, expectation4)
    task.add(condition: Conditions.Empty())
    task.add(observer: observer)
    Self.taskQueue.add(task)
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      task.cancel()
    }
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 3.0, enforceOrder: true)
  }
  internal func testAddCondition() {
    final class TestTask: ProducerTask<Int, Error> {
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
    
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    var cancellables = [AnyCancellable]()
    let dependencyTask = TestTask().name("depTestTask1")
    let task = TestTask().name("testTask1")
    task.add(condition: Conditions.NoCancelledDependencies())
      .sink {
        switch $0 {
        case .failure(.haveCancelledFailure):
          expectation1.fulfill()
        default:
          XCTAssertTrue(false)
        }
      } receiveValue: { (_) in
        XCTAssertTrue(false)
      }
      .store(in: &cancellables)
    
    task.add(dependency: dependencyTask)
    Self.taskQueue.add(dependencyTask)
    Self.taskQueue.add(task)
      .sink {
        switch $0 {
        case .failure(.cancelled):
          expectation2.fulfill()
        default:
          XCTAssertTrue(false)
        }
      } receiveValue: { (_) in
        XCTAssertTrue(false)
      }
      .store(in: &cancellables)
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      dependencyTask.cancel()
    }
    
    wait(for: [expectation1, expectation2], timeout: 5.0, enforceOrder: true)
  }
  //
  internal func testQueues() {
    final class TestTask: ProducerTask<Int, Error> {
      override func execute() -> AnyPublisher<Int, Error> {
        Future { (promise) in
          dispatchPrecondition(condition: .onQueue(self.workDispatchQueue))
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            promise(.success(21))
          }
        }.eraseToAnyPublisher()
      }
      let workDispatchQueue: DispatchQueue
      init(workDispatchQueue: DispatchQueue) {
        self.workDispatchQueue = workDispatchQueue
      }
    }
    
    let expectation = XCTestExpectation()
    var cancellables = [AnyCancellable]()
    let task = TestTask(workDispatchQueue: Self.workDispatchQueue)
    task.publisher
      .subscribe(on: Self.deliverDispatchQueue)
      .receive(on: Self.deliverDispatchQueue)
      .map { (value) -> Int in
        dispatchPrecondition(condition: .onQueue(Self.deliverDispatchQueue))
        return value
      }
      .receive(on: DispatchQueue.main)
      .sink { (completion) in
        dispatchPrecondition(condition: .onQueue(.main))
        switch completion {
        case .failure:
          XCTAssertTrue(false)
        case .finished:
          expectation.fulfill()
        }
      } receiveValue: { (value) in
        dispatchPrecondition(condition: .onQueue(.main))
        XCTAssert(value == 21)
      }
      .store(in: &cancellables)
    Self.taskQueue.add(task)
    
    wait(for: [expectation], timeout: 3.0)
  }
}
