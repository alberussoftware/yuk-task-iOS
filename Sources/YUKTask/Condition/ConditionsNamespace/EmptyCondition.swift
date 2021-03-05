//
//  EmptyCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/18/20.
//

import Combine

// MARK: -
extension Conditions {
  public struct Empty: Condition {
    public typealias Failure = Never
    
    public func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure> {
      Just(()).eraseToAnyPublisher()
    }
  }
}
