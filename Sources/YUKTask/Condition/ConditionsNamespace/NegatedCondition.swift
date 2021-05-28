//
//  NegatedCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Combine

// MARK: -
extension Conditions {
  public final class Negated<BaseCondition: Condition>: Condition {
    public typealias Failure = Negated.Error
    
    public let baseCondition: BaseCondition
    
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      baseCondition.dependency(for: task)
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure> {
      baseCondition.evaluate(for: task)
        .catch { (_) in Result.Publisher(.success).eraseToAnyPublisher() }
        .setFailureType(to: Failure.self)
        .flatMap { (_) in Result.Publisher(.failure(.reverseFailure)).eraseToAnyPublisher() }
        .eraseToAnyPublisher()
    }
    
    public init(_ condition: BaseCondition) {
      baseCondition = condition
    }
  }
}

extension Conditions.Negated {
  public enum Error: Swift.Error {
    case reverseFailure
  }
}
