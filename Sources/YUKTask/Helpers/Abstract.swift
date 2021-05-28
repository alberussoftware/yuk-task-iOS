//
//  HelperFunction.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/30/21.
//

// MARK: -
@inline(never) @usableFromInline internal func _abstract(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError("\(function) must be overridden", file: file, line: line)
}
