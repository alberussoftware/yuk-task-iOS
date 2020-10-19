//
//  NegatedCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions {
  
public struct Negated<Base: Condition> {
  // MARK: - API
  // MARK:
  public typealias Failure = Error
  
  // MARK:
  public let condition: Base
  
  // MARK:
  public init(_ condition: Base) {
    self.condition = condition
  }
}

}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.Negated {
  
public enum Error: Swift.Error {
  case reverseFailure
}

}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Conditions.Negated: Condition {
  public func dependency<T: ProducerTaskProtocol>(for task: T) -> NonFailTask? {
    condition.dependency(for: task)
  }
  
  public func evaluate<T: ProducerTaskProtocol>(for task: T, completion: @escaping (Result<Void, Failure>) -> Void) {
    condition.evaluate(for: task) { (result) in
      if case .success = result {
        completion(.failure(.reverseFailure))
      }
      else {
        completion(.success)
      }
    }
  }
}
