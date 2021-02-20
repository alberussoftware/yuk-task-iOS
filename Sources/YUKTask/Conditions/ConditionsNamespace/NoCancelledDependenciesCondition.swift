//
//  NoCancelledDependenciesCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

// MARK: -
extension Conditions {
  public struct NoCancelledDependencies: Condition {
    public typealias Failure = NoCancelledDependencies.Error
    
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      nil
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>, with promise: Promise) {
      task._operation
        .dependencies
        .allSatisfy { !$0.isCancelled }
        ? promise(.success) : promise(.failure(.haveCancelledFailure))
    }
  }
}

// MARK: -
extension Conditions.NoCancelledDependencies {
  public enum Error: Swift.Error {
    case haveCancelledFailure
  }
}
