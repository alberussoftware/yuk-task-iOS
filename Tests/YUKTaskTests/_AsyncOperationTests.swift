//
//  _AsyncOperationTests.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/2/21.
//

import XCTest
@testable import YUKTask

// MARK: -
final class _AsyncOperationTests: XCTestCase {
	func testWillEnqueueBeforeAdding() {
		let expectation = XCTestExpectation()
		
		let operation = _AsyncOperation { (_, completion) in
      completion(.finish)
    } finished: { (_) in
      expectation.fulfill()
    }
		operation.willEnqueue()
    Self.operationQueue.addOperation(operation)
		
		wait(for: [expectation], timeout: 1.0)
	}
	func testWillEnqueueAfterAdding() {
		let expectation = XCTestExpectation()
		
    let operation = _AsyncOperation { (_, completion) in
      completion(.finish)
    } finished: { (_) in
      expectation.fulfill()
    }
    Self.operationQueue.addOperation(operation)
    DispatchQueue.global().asyncAfter(wallDeadline: .now() + 2.0) {
      operation.willEnqueue()
    }
		
		wait(for: [expectation], timeout: 3.0)
	}
  //
  func testProperlyInvokedClosures() {
    let expectation1 = XCTestExpectation()
    let expectation2 = XCTestExpectation()
    let expectation3 = XCTestExpectation()
    let expectation4 = XCTestExpectation()

    let operation = _AsyncOperation { (op, completion) in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        XCTAssertTrue(op.isExecuting)
        expectation2.fulfill()
        completion(.finish)
      }
    } preparation: { (op, completion) in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        XCTAssertFalse(op.isExecuting)
        expectation1.fulfill()
        completion(.finish)
      }
    } finishing: { (op) in
        XCTAssertFalse(op.isFinished)
        expectation3.fulfill()
    } finished: { (op) in
        XCTAssertTrue(op.isFinished)
        expectation4.fulfill()
    }
    operation.willEnqueue()
    Self.operationQueue.addOperation(operation)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 5.0, enforceOrder: true)
  }
	//
	func testCancelationDuringPreparation() {
		let expectation = XCTestExpectation()
		
		let operation = _AsyncOperation { (op, completion) in
		  XCTAssertTrue(op.isCancelled)
      completion(.finish)
    } preparation: { (_, completion) in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
        completion(.finish)
      }
    } finished: { (_) in
			expectation.fulfill()
		}
		operation.willEnqueue()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      operation.cancel()
    }
    Self.operationQueue.addOperation(operation)
    
		wait(for: [expectation], timeout: 2.0)
	}
	func testCancelationDuringWork() {
		let expectation = XCTestExpectation()

    let operation = _AsyncOperation { (op, completion) in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
        XCTAssertTrue(op.isCancelled)
        completion(.finish)
      }
    } finished: { (_) in
      expectation.fulfill()
    }
		operation.willEnqueue()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      operation.cancel()
    }
    Self.operationQueue.addOperation(operation)

		wait(for: [expectation], timeout: 4.0)
	}
  //
  func testReferenceCycles() {
    let expectation = XCTestExpectation()
    weak var operationQueue: OperationQueue?
    weak var operation: _AsyncOperation?
    
    do {
      let _operationQueue = OperationQueue()
      let _operation = _AsyncOperation { (_, completion) in
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
          completion(.finish)
        }
      }
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
  
  static var allTests = [
    ("testWillEnqueueBeforeAdding", testWillEnqueueBeforeAdding),
    ("testWillEnqueueAfterAdding", testWillEnqueueAfterAdding),
    ("testProperlyInvokedClosures", testProperlyInvokedClosures),
    ("testCancelationDuringPreparation", testCancelationDuringPreparation),
    ("testCancelationDuringWork", testCancelationDuringWork),
    ("testReferenceCycles", testReferenceCycles),
  ]
}
