//
//  Condition.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

import class Combine.Future

// MARK: -
public protocol Condition {
  associatedtype Failure: Error
  
  typealias Future = Combine.Future<Void, Failure>
  typealias Promise = Future.Promise
  
  func dependency<O, F: Error>(for task: ProducerTask<O, F>) -> AnyProducerTask?
  func evaluate<O, F: Error>(for task: ProducerTask<O, F>, with promise: @escaping Promise)
}
