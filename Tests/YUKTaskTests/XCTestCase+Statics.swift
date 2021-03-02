//
//  XCTestCase+Statics.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/16/21.
//

import class Dispatch.DispatchQueue
import class Foundation.OperationQueue
import class YUKTask.TaskQueue
import class XCTest.XCTestCase

// MARK: -
extension XCTestCase {
  static let workDispatchQueue = DispatchQueue(label: "com.YUKTaskTests-work", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
  static let deliverDispatchQueue = DispatchQueue(label: "com.YUKTaskTests-deliver", qos: .userInitiated, autoreleaseFrequency: .workItem)
  static let taskQueue = TaskQueue().name("com.YUKTaskTests").qualityOfService(.userInitiated).underlyingQueue(workDispatchQueue)
  static let operationQueue: OperationQueue = { $0.name = "com.YUKTaskTests"; return $0 }(OperationQueue())
}
