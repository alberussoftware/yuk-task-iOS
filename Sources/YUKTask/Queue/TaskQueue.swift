//
//  TaskQueue.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/3/20.
//

import class Foundation.OperationQueue
import class Dispatch.DispatchQueue
import class YUKLock.UnfairLocked
import class Combine.Future

// MARK: -
internal struct _TaskQueueObserver: Observer {
  private weak var taskQueue: TaskQueue?
  
  internal func task<O1, F1: Error, O2, F2: Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>) {
    taskQueue?.add(newTask)
  }
  internal func taskDidFinish<O, F: Error>(_ task: ProducerTask<O, F>) {
    taskQueue?.$_tasks.write { $0[task.id] = nil }
  }
  
  internal init(taskQueue: TaskQueue) {
    self.taskQueue = taskQueue
  }
}

// MARK: -
public final class TaskQueue {
  // MARK: Internal Props
  internal let _operationQueue: OperationQueue
  //
	@UnfairLocked internal var _tasks = [AnyHashable: AnyObject]()
  
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
  @discardableResult public func add<O, F: Error>(_ task: GroupProducerTask<O, F>) -> Future<O, F> {
    task._taskQueue._operationQueue.underlyingQueue = underlyingQueue
    return add(task as ProducerTask<O, F>)
  }
  @discardableResult public func add<I, O, F: Error>(_ task: GroupConsumerProducerTask<I, O, F>) -> Future<O, F> {
    task._taskQueue._operationQueue.underlyingQueue = underlyingQueue
    return add(task as ProducerTask<O, F>)
  }
  @discardableResult public func add<O, F: Error>(_ task: ProducerTask<O, F>) -> Future<O, F> {
    $_tasks.write { $0[task.id] = task }
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
  @discardableResult public func name(_ string: String) -> Self {
    _operationQueue.name = string
    return self
  }
  @discardableResult public func qualityOfService(_ qos: QualityOfService) -> Self {
    _operationQueue.qualityOfService = qos._underline
    return self
  }
  @discardableResult public func maxConcurrentTasks(_ count: Int) -> Self {
    _operationQueue.maxConcurrentOperationCount = count
    return self
  }
  @discardableResult public func underlyingQueue(_ queue: DispatchQueue) -> Self {
    _operationQueue.underlyingQueue = queue
    return self
  }
  @discardableResult public func isSuspended(_ suspended: Bool) -> Self {
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
