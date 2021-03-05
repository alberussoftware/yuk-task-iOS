//
//  AnyCancellable+Dictionary.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 3/4/21.
//

import YUKLock

import class Combine.AnyCancellable

// MARK: -
extension AnyCancellable {
  public func store<Key: Hashable>(in dictionary: UnfairLocked<[Key: AnyCancellable]>, at key: Key) {
    dictionary.wrappedValue[key] = self
  }
}

extension AnyCancellable {
  public func store<Key: Hashable>(in dictionary: RecursiveLocked<[Key: AnyCancellable]>, at key: Key) {
    dictionary.wrappedValue[key] = self
  }
}
