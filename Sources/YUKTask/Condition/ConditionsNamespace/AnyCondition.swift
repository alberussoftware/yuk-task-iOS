//
//  AnyCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/18/21.
//

import Combine

// MARK: -
@usableFromInline
internal class _AnyConditionBox {
  @inlinable internal func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
    _abstract()
  }
  @inlinable internal func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Error> {
    _abstract()
  }
  
  @inlinable internal init() { }
}

// MARK: -
@usableFromInline
internal final class _ConditionBox<BaseCondition: Condition>: _AnyConditionBox {
  @usableFromInline internal var baseCondition: BaseCondition
  
  @inlinable override internal func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
    baseCondition.dependency(for: task)
  }
  @inlinable override internal func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Error> {
    baseCondition.evaluate(for: task).mapError { $0 as Error }.eraseToAnyPublisher()
  }
  
  @inlinable internal init(_ condition: BaseCondition) {
    baseCondition = condition
  }
  @inlinable deinit { }
}

// MARK: -
extension Conditions {
  public struct AnyCondition: Condition {
    public typealias Failure = Error
    
    @usableFromInline internal let _box: _AnyConditionBox
    
    @inlinable public func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      _box.dependency(for: task)
    }
    @inlinable public func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Error> {
      _box.evaluate(for: task)
    }
    
    @inlinable public init<BaseCondition: Condition>(_ condition: BaseCondition) {
      _box = _ConditionBox(condition)
    }
  }
}
