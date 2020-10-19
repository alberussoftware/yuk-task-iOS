//
//  Condition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol Condition {
  // MARK:
  associatedtype Failure: Error
  
  // MARK:
  func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask?
  
  func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void)
}


@usableFromInline
internal class _AnyConditionBaseBox<Failure: Error>: Condition {
  // MARK: - API
  // MARK:
  @inlinable
  internal func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? {
    _abstract()
  }
  
  @inlinable
  internal func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    _abstract()
  }

  // MARK:
  @inlinable
  internal init() {}

  @inlinable
  deinit {}
}


@usableFromInline
internal final class _AnyConditionBox<Base: Condition>: _AnyConditionBaseBox<Error> {
  // MARK: - API
  // MARK:
  @usableFromInline
  internal typealias Failure = Error
  
  // MARK:
  @inlinable
  internal override func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? {
    base.dependency(for: task)
  }

  @inlinable
  internal override func evaluate<T: ProducerTaskProtocol>(
    for task: T,
    completion: @escaping (Result<Void, Failure>) -> Void
  ) {
    let newCompletion: (Result<Void, Base.Failure>) -> Void = { completion($0.mapError { $0 as Failure }) }
    base.evaluate(for: task, completion: newCompletion)
  }

  // MARK:
  @usableFromInline
  internal let base: Base

  // MARK:
  @inlinable
  internal init(_ base: Base) {
    self.base = base
  }

  @inlinable
  deinit {}
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public struct AnyCondition: Condition {
  // MARK:
  @usableFromInline
  internal let box: _AnyConditionBaseBox<Failure>
  
  // MARK: - API
  // MARK:
  public typealias Failure = Error
  
  // MARK:
  @inlinable
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? {
    box.dependency(for: task)
  }

  @inlinable
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    box.evaluate(for: task, completion: completion)
  }
  
  // MARK:
  @inlinable
  public init<C: Condition>(_ base: C) {
    box = _AnyConditionBox(base)
  }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum Conditions {}
