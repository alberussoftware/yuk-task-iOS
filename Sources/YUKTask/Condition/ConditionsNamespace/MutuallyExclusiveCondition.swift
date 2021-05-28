//
//  MutuallyExclusiveCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Combine

// MARK: -
extension Conditions {
  public struct MutuallyExclusive<Category>: Condition {
    public typealias Failure = Never
    
    public func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure> {
      Result.Publisher(.success).eraseToAnyPublisher()
    }
  }
}
