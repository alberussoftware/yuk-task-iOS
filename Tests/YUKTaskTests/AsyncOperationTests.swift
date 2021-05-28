//
//  _AsyncOperationTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/2/21.
//

import XCTest
import Combine
@testable import YUKTask

// MARK: -
internal final class AsyncOperationTests: XCTestCase {
  // MARK: Internal Static Props
  internal static var allTests = [("testWillEnqueueBeforeAdding", testWillEnqueueBeforeAdding),
                                  ("testWillEnqueueAfterAdding", testWillEnqueueAfterAdding),
                                  
                                  ("testProperlyInvokedClosures", testProperlyInvokedClosures),
                                  
                                  ("testCancelationDuringPreparation", testCancelationDuringPreparation),
                                  ("testCancelationDuringWork", testCancelationDuringWork),
                                  
                                  ("testReferenceCycles", testReferenceCycles)]
  
  // MARK: Internal Methods
  internal func testWillEnqueueBeforeAdding() {
    let expectation = XCTestExpectation()
    
    let operation = AsyncOperation(work: { (_) in
      Just(()).eraseToAnyPublisher()
    }, onFinished: { (_) in
      expectation.fulfill()
    })
    operation.willEnqueue()
    Self.operationQueue.addOperation(operation)
    
    wait(for: [expectation], timeout: 1.0)
  }
  internal func testWillEnqueueAfterAdding() {
    let expectation = XCTestExpectation()
    
    let operation = AsyncOperation(work: { (_) in
      Just(()).eraseToAnyPublisher()
    }, onFinished: { (_) in
      expectation.fulfill()
    })
    Self.operationQueue.addOperation(operation)
    DispatchQueue.global().asyncAfter(wallDeadline: .now() + 2.0) {
      operation.willEnqueue()
    }
    
    wait(for: [expectation], timeout: 3.0)
  }
  //
  internal func testProperlyInvokedClosures() {
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    let expectation3 = XCTestExpectation()
    let expectation4 = XCTestExpectation()
    
    let operation = AsyncOperation { (op) in
      Future { (promise) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
          XCTAssertFalse(op.isExecuting)
          expectation1.fulfill()
          promise(.success)
        }
      }.eraseToAnyPublisher()
      
    } work: { (op) in
      Future { (promise) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
          XCTAssertTrue(op.isExecuting)
          expectation2.fulfill()
          promise(.success)
        }
      }.eraseToAnyPublisher()
      
    } onFinishing: { (op) in
      XCTAssertFalse(op.isFinished)
      expectation3.fulfill()
      return Just(()).eraseToAnyPublisher()
      
    } onFinished: { (op) in
      XCTAssertTrue(op.isFinished)
      expectation4.fulfill()
    }
    operation.willEnqueue()
    Self.operationQueue.addOperation(operation)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 5.0, enforceOrder: true)
  }
  //
  internal func testCancelationDuringPreparation() {
    let expectation = XCTestExpectation()
    
    let operation = AsyncOperation { (_) in
      Future { (promise) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
          promise(.success)
        }
      }.eraseToAnyPublisher()
      
    } work: { (op) in
      XCTAssertTrue(op.isCancelled)
      return Just(()).eraseToAnyPublisher()
      
    } onFinished: { (_) in
      expectation.fulfill()
      
    }
    operation.willEnqueue()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      operation.cancel()
    }
    Self.operationQueue.addOperation(operation)
    
    wait(for: [expectation], timeout: 2.0)
  }
  internal func testCancelationDuringWork() {
    let expectation = XCTestExpectation()
    
    let operation = AsyncOperation(work: { (op) in
      Future { (promise) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
          XCTAssertTrue(op.isCancelled)
          promise(.success)
        }
      }.eraseToAnyPublisher()
      
    }, onFinished: { (_) in
      expectation.fulfill()
    })
    operation.willEnqueue()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      operation.cancel()
    }
    Self.operationQueue.addOperation(operation)
    
    wait(for: [expectation], timeout: 4.0)
  }
  //
  internal func testReferenceCycles() {
    let expectation = XCTestExpectation()
    weak var operationQueue: OperationQueue?
    weak var operation: AsyncOperation?
    
    do {
      let _operationQueue = OperationQueue()
      let _operation = AsyncOperation(work: { (_) in
        Future { (promise) in
          DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
            promise(.success)
          }
        }.eraseToAnyPublisher()
      })
      _operation.willEnqueue()
      _operationQueue.addOperation(_operation)
      
      operationQueue = _operationQueue
      operation = _operation
    }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(4)) {
      XCTAssertNil(operationQueue)
      XCTAssertNil(operation)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
}
