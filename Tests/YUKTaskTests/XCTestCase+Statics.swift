//
//  XCTestCase+Statics.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/16/21.
//
import Foundation
import class YUKTask.TaskQueue
import class XCTest.XCTestCase

// MARK: -
extension XCTestCase {
  static let workDispatchQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!)-work", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
  static let deliverDispatchQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!)-deliver", qos: .userInitiated, autoreleaseFrequency: .workItem)
  static let taskQueue = TaskQueue().name(Bundle.main.bundleIdentifier!).qualityOfService(.userInitiated).underlyingQueue(workDispatchQueue)
  static let operationQueue: OperationQueue = { $0.name = Bundle.main.bundleIdentifier!; return $0 }(OperationQueue())
}
