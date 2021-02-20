//
//  XCTestCase+Error.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/16/21.
//

import class XCTest.XCTestCase

// MARK: -
extension XCTestCase {
  enum Error: Swift.Error {
    case cancelled
    case oops
  }
}
