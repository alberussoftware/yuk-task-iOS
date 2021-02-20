//
//  ConditionEvaluator.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/18/20.
//


//
//internal final class _ConditionEvaluator {
//  // MARK:
//  private let lock = UnfairLock()
//
//  // MARK:
//  private init() { }
//  
//  // MARK: -
//  // MARK:
//  internal func evaluate<T: ProducerTaskProtocol>(
//  _ conditions: [AnyCondition],
//    for task: T,
//    completion: @escaping ([Result<Void, Error>]) -> Void
//  ) {
//    let group = DispatchGroup()
//
//    var results = [Result<Void, Error>]()
//    results.reserveCapacity(conditions.count)
//    
//    conditions.forEach {
//      group.enter()
//      $0.evaluate(for: task) { (result) in
//        self.lock.sync { results.append(result) }
//        group.leave()
//      }
//    }
//    
//    group.notify(queue: .global(qos: .userInitiated)) { completion(results) }
//  }
//  
//  // MARK:
//  internal static let shared = _ConditionEvaluator()
//}
