//
//  AdditionalTasksTests.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/20/20.
//

import XCTest
@testable import YUKTask

final class AdditionalTasksTests: XCTestCase {
  // MARK:
  private let queue =
    TaskQueue(
      name: "\(Bundle.main.bundleIdentifier!).\(String(describing: TasksNamespaceTests.self))",
      qos: .userInitiated
    )
  
  // MARK: - API
  // MARK:
  func testBlockProducerTask() {
    let expec = XCTestExpectation()
    
    let task =
      BlockProducerTask<Int, String>(
        name: "BlockProducerTask",
        qos: .userInitiated, priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
      }
      .recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
        case .failure:
          XCTFail()
        }
        
        expec.fulfill()
      }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 2.0)
  }
  
  func testBlockTask() {
    let expec = XCTestExpectation()
    
    let task =
      BlockTask<String>(
        name: "BlockProducerTask",
        qos: .userInitiated, priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.failure(.provided("Oops")))
      }
      .recieve {
        switch $0 {
        case .success, .failure(.internal):
          XCTFail()
        case let .failure(.provided(error)):
          XCTAssertEqual(error, "Oops")
        }
        
        expec.fulfill()
      }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 2.0)
  }
  
  func testNonFailBlockTask() {
    let expec = XCTestExpectation()
    
    let task =
      NonFailBlockTask(
        name: "BlockProducerTask",
        qos: .userInitiated, priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success)
      }
      .recieve {
        switch $0 {
        case .success:
          XCTAssertTrue(true)
        case .failure:
          XCTFail()
        }
        
        expec.fulfill()
      }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 2.0)
  }
  
  func testNonFailBlockProducerTask() {
    let expec = XCTestExpectation()
    
    let task =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
      }
      .recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 21)
        case .failure:
          XCTFail()
        }
        
        expec.fulfill()
      }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 2.0)
  }
  
  // MARK:
  func testBlockConsumerProducerTask() {
    let expec = XCTestExpectation()
    
    let producerTask =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
      }
    
    let consumerTask =
      BlockConsumerProducerTask<Int, Int, String>(
        qos: .userInitiated,
        priority: .veryHigh,
        producing: producerTask
      ) { (task, consumed, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        
        switch consumed {
        case let .success(value):
          XCTAssertEqual(value, 21)
          finish(.success(value + 21))
        case .failure:
          XCTFail()
        }
      }
      .recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 42)
          expec.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    queue.addTask(producerTask)
    queue.addTask(consumerTask)
    
    wait(for: [expec], timeout: 3.0)
  }
  
  func testBlockConsumerTask() {
    let expec = XCTestExpectation()
    
    let producerTask =
      BlockProducerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
    }
    
    let consumerTask =
      BlockConsumerTask<Int, String>(
        qos: .userInitiated,
        priority: .veryHigh,
        producing: producerTask
      ) { (task, consumed, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        
        switch consumed {
        case let .success(value):
          XCTAssertEqual(value, 21)
          finish(.success)
        case .failure:
          XCTFail()
        }
      }
      .recieve {
        switch $0 {
        case .success:
          XCTAssertTrue(true)
          expec.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    queue.addTask(producerTask)
    queue.addTask(consumerTask)
    
    wait(for: [expec], timeout: 3.0)
  }
  
  func testNonFailBlockConsumerTask() {
    let expec = XCTestExpectation()
    
    let producerTask =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
      }
    
    let consumerTask =
      NonFailBlockConsumerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh,
        producing: producerTask
      ) { (task, consumed, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        
        switch consumed {
        case let .success(value):
          XCTAssertEqual(value, 21)
          finish(.success)
        case .failure:
          XCTFail()
        }
      }
      .recieve {
        switch $0 {
        case .success:
          XCTAssertTrue(true)
          expec.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    queue.addTask(producerTask)
    queue.addTask(consumerTask)
    
    wait(for: [expec], timeout: 3.0)
  }
  
  func testNonFailBlockConsumerProducerTask() {
    let expec = XCTestExpectation()
    
    let producerTask =
      NonFailBlockProducerTask<Int>(
        qos: .userInitiated,
        priority: .veryHigh
      ) { (task, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        finish(.success(21))
      }
    
    let consumerTask =
      NonFailBlockConsumerProducerTask<Int, Int>(
        qos: .userInitiated,
        priority: .veryHigh,
        producing: producerTask
      ) { (task, consumed, finish) in
        Thread.sleep(forTimeInterval: 1.0)
        
        switch consumed {
        case let .success(value):
          XCTAssertEqual(value, 21)
          finish(.success(value + 21))
        case .failure:
          XCTFail()
        }
      }
      .recieve {
        switch $0 {
        case let .success(value):
          XCTAssertEqual(value, 42)
          expec.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    queue.addTask(producerTask)
    queue.addTask(consumerTask)
    
    wait(for: [expec], timeout: 3.0)
  }
  
  // MARK:
  func testEmptyTask() {
    let expec = XCTestExpectation()
    
    let task =
      EmptyTask(qos: .userInitiated, priority: .veryHigh)
        .recieve {
          switch $0 {
          case .success:
            XCTAssertTrue(true)
            expec.fulfill()
          case .failure:
            XCTFail()
          }
        }
    
    queue.addTask(task)
    
    wait(for: [expec], timeout: 1.0)
  }
  
  // MARK:
  func testGatedTask() {
    let expec = XCTestExpectation()
    
    final class MyOperation: Operation { override func main() { Thread.sleep(forTimeInterval: 2.0) } }
    
    let myop = MyOperation()
    
    let task =
      GatedTask(
        qos: .userInitiated,
        priority: .veryHigh,
        operation: myop
      )
      .recieve {
        switch $0 {
        case .success:
          XCTAssertTrue(true)
          expec.fulfill()
        case .failure:
          XCTFail()
        }
      }
    
    queue.addTask(task)

    wait(for: [expec], timeout: 3.0)
  }
  
  // MARK:
  static var allTests = [
    ("testBlockProducerTask", testBlockProducerTask),
    ("testBlockTask", testBlockTask),
    ("testNonFailBlockTask", testNonFailBlockTask),
    ("testNonFailBlockProducerTask", testNonFailBlockProducerTask),
    ("testBlockConsumerProducerTask", testBlockConsumerProducerTask),
    ("testBlockConsumerTask", testBlockConsumerTask),
    ("testNonFailBlockConsumerTask", testNonFailBlockConsumerTask),
    ("testNonFailBlockConsumerProducerTask", testNonFailBlockConsumerProducerTask),
    ("testEmptyTask", testEmptyTask),
    ("testGatedTask", testGatedTask),
  ]
}
