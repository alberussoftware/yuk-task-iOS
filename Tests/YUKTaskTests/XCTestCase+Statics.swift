//
//  XCTestCase+Statics.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/16/21.
//
import Foundation
import XCTest
import YUKTask

// MARK: -
extension XCTestCase {
  internal static let workDispatchQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!)-work", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
  internal static let deliverDispatchQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!)-deliver", qos: .userInitiated, autoreleaseFrequency: .workItem)
  internal static let taskQueue = TaskQueue().name(Bundle.main.bundleIdentifier!).qualityOfService(.userInitiated).underlyingQueue(workDispatchQueue)
  internal static let operationQueue: OperationQueue = { $0.name = Bundle.main.bundleIdentifier!; return $0 }(OperationQueue())
}
