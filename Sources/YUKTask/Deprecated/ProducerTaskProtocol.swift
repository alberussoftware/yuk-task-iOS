//
//  ProducerTaskProtocol.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/19/20.
//

//import class Combine.Future
//
//// MARK: -
//public protocol ProducerTaskProtocol: AnyObject, Identifiable {
//  associatedtype Output
//  associatedtype Failure: Error
//  
//  typealias Produced = Result<Output, Failure>
//  typealias Future = Combine.Future<Output, Failure>
//  typealias Promise = Future.Promise
//  
//  var name: String? { get }
//  var qualityOfService: QualityOfService { get }
//  var queuePriority: QueuePriority { get }
//  //
//  var isExecuting: Bool { get }
//  var isFinished: Bool { get }
//  var isCancelled: Bool { get }
//  //
//  var produced: Produced? { get }
//  //
//  var observers: [Observer] { get }
//  //
//  var publisher: Future { get }
//  
//  func execute(_ promise: @escaping Promise)
//  func finishing(with produced: Produced)
//  func finished(with produced: Produced)
//  //
//  func cancel()
//  //
//  func produce<T: ProducerTaskProtocol>(new task: T)
//  //
//  @discardableResult func add<C: Condition>(condition: C) -> Self
//  @discardableResult func add<O: Observer>(observer: O) -> Self
//  @discardableResult func add<T: ProducerTaskProtocol>(dependency task: T) -> Self
//  @discardableResult func name(_ string: String) -> Self
//  @discardableResult func qualityOfService(_ qos: QualityOfService) -> Self
//  @discardableResult func queuePriority(_ priority: QueuePriority) -> Self
//}
