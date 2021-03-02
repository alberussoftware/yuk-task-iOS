//
//  NegatedCondition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/17/20.
//

// MARK: -
extension Conditions {
  public final class Negated<BaseCondition: Condition>: Condition {
    public typealias Failure = Negated.Error
    
    public let baseCondition: BaseCondition
 
    public func dependency<O, F: Swift.Error>(for task: ProducerTask<O, F>) -> AnyProducerTask? {
      baseCondition.dependency(for: task)
    }
    public func evaluate<O, F: Swift.Error>(for task: ProducerTask<O, F>, with promise: @escaping Promise) {
      baseCondition.evaluate(for: task) { (result) in
        switch result {
        case .failure(_):
          promise(.success)
        case .success:
          promise(.failure(.reverseFailure))
        }
      }
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
