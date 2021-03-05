//
//  SilentCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Combine

// MARK: -
extension Conditions {
  public final class Silent<BaseCondition: Condition>: Condition {
    public typealias Failure = BaseCondition.Failure
    
    public let baseCondition: BaseCondition
    
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure> {
      baseCondition.evaluate(for: task)
    }
    
    public init(_ condition: BaseCondition) {
      baseCondition = condition
    }
  }
}
