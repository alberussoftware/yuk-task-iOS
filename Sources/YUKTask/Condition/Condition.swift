//
//  Condition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

import Combine

// MARK: -
public protocol Condition {
  associatedtype Failure: Error
    
  func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask?
  func evaluate<O, F: Error>(for task: ProducerTask<O, F>) -> AnyPublisher<Void, Failure>
}
