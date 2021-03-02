//
//  SilentCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

// MARK: -
extension Conditions {
  public final class Silent<BaseCondition: Condition>: Condition {
    public typealias Failure = BaseCondition.Failure
    
    public let baseCondition: BaseCondition
    
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>, with promise: @escaping Promise) {
      baseCondition.evaluate(for: task, with: promise)
    }
    
    public init(_ condition: BaseCondition) {
      baseCondition = condition
    }
  }
}
