//
//  Combine+Additions.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 3/4/21.
//

import YUKLock
import Combine

// MARK: -
extension Subscribers.Sink where Input == Void  {
  convenience init(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void)) {
    self.init(receiveCompletion: receiveCompletion, receiveValue: { })
  }
}
 
extension Subscribers.Sink where Input == Void, Failure == Never {
  convenience init() {
    self.init(receiveCompletion: { (_) in })
  }
}

extension Publisher {
  public func eraseOutputToVoid() -> AnyPublisher<Void, Failure> {
    map { (_) in () }.eraseToAnyPublisher()
  }
}
