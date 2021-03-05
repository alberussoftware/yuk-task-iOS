//
//  TaskQueue.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/3/20.
//

import struct Combine.AnyPublisher
import class Foundation.OperationQueue
import class Dispatch.DispatchQueue
import class YUKLock.UnfairLocked

// MARK: -
public final class TaskQueue {
  // MARK: Internal Props
  internal let _operationQueue: OperationQueue
  //
	@UnfairLocked
  internal var _tasks = [AnyHashable: AnyObject]()
  
  // MARK: Public Static Props
  public static let main = TaskQueue(operationQueue: OperationQueue.main)
  //
  public static var defaultMaxConcurrentTaskCount: Int { OperationQueue.defaultMaxConcurrentOperationCount }
  
  // MARK: Public Props
  public var name: String? { _operationQueue.name }
  public var qualityOfService: QualityOfService { .init(_operationQueue.qualityOfService) }
  public var maxConcurrentTasks: Int { _operationQueue.maxConcurrentOperationCount }
  public var underlyingQueue: DispatchQueue? { _operationQueue.underlyingQueue }
  public var isSuspended: Bool { _operationQueue.isSuspended }
  
  // MARK: Public Funcs
  @discardableResult
  public func add<O, F: Error>(_ task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    if let taskQueueContainable = task as? _TaskQueueContainable { taskQueueContainable._taskQueue._operationQueue.underlyingQueue = underlyingQueue }
    _tasks[task.id] = task
    task.add(observer: _TaskQueueObserver(taskQueue: self))
    task._operation.willEnqueue()
    _operationQueue.addOperation(task._operation)
    return task.publisher
  }
  //
  public func cancelAllTasks() {
    _operationQueue.cancelAllOperations()
  }
  public func waitUntilAllTasksAreFinished() {
    _operationQueue.waitUntilAllOperationsAreFinished()
  }
  //
  @discardableResult
  public func name(_ string: String) -> Self {
    _operationQueue.name = string
    return self
  }
  @discardableResult
  public func qualityOfService(_ qos: QualityOfService) -> Self {
    _operationQueue.qualityOfService = qos._underline
    return self
  }
  @discardableResult
  public func maxConcurrentTasks(_ count: Int) -> Self {
    _operationQueue.maxConcurrentOperationCount = count
    return self
  }
  @discardableResult
  public func underlyingQueue(_ queue: DispatchQueue) -> Self {
    _operationQueue.underlyingQueue = queue
    return self
  }
  @discardableResult
  public func isSuspended(_ suspended: Bool) -> Self {
    _operationQueue.isSuspended = suspended
    return self
  }
  
  // MARK: Private Inits
  private init(operationQueue: OperationQueue) {
    _operationQueue = operationQueue
  }
  
  // MARK: Public Inits
  public init() {
    _operationQueue = .init()
  }
}
