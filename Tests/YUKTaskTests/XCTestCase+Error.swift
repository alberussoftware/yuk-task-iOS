//
//  XCTestCase+Error.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/16/21.
//

import XCTest

// MARK: -
extension XCTestCase {
  internal enum Error: Swift.Error {
    case cancelled
    case oops
  }
}
