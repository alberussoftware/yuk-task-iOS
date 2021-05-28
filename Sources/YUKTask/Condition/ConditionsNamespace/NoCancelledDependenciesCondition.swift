//
//  NoCancelledDependenciesCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

import Combine

// MARK: -
extension Conditions {
  public struct NoCancelledDependencies: Condition {
    public typealias Failure = NoCancelledDependencies.Error
    
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure> {
      task.operation
        .dependencies
        .allSatisfy { !$0.isCancelled }
        ? Result.Publisher(.success).eraseToAnyPublisher()
        : Result.Publisher(.failure(.haveCancelledFailure)).eraseToAnyPublisher()
    }
  }
}

// MARK: -
extension Conditions.NoCancelledDependencies {
  public enum Error: Swift.Error {
    case haveCancelledFailure
  }
}
