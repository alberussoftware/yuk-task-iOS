//
//  TaskQueue.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/3/20.
//

import Combine
import Foundation
import YUKLock

// MARK: -
public final class TaskQueue {
  // MARK: Public Static Props
  public static let main = TaskQueue(operationQueue: .main)
  //
  public static var defaultMaxConcurrentTaskCount: Int { OperationQueue.defaultMaxConcurrentOperationCount }
  
  // MARK: Internal Props
  internal let operationQueue: OperationQueue
  //
  @UnfairLocked internal var tasks = [AnyHashable: AnyObject]()
  
  // MARK: Public Props
  public var name: String? { operationQueue.name }
  public var qualityOfService: QualityOfService { .init(operationQueue.qualityOfService) }
  public var maxConcurrentTasks: Int { operationQueue.maxConcurrentOperationCount }
  public var underlyingQueue: DispatchQueue? { operationQueue.underlyingQueue }
  public var isSuspended: Bool { operationQueue.isSuspended }
  
  // MARK: Public Methods
  @discardableResult public func add<O, F: Error>(_ task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    if let taskQueueContainable = task as? TaskQueueContainable { taskQueueContainable.taskQueue.operationQueue.underlyingQueue = underlyingQueue }
    task.add(observer: TaskObserver(taskQueue: self))
    task.operation.willEnqueue()
    
    tasks[task.id] = task
    
    operationQueue.addOperation(task.operation)
    
    return task.publisher
  }
  //
  public func cancelAllTasks() {
    operationQueue.cancelAllOperations()
  }
  public func waitUntilAllTasksAreFinished() {
    operationQueue.waitUntilAllOperationsAreFinished()
  }
  //
  @discardableResult public func name(_ string: String) -> Self {
    operationQueue.name = string
    return self
  }
  @discardableResult public func qualityOfService(_ qos: QualityOfService) -> Self {
    operationQueue.qualityOfService = qos._underline
    return self
  }
  @discardableResult public func maxConcurrentTasks(_ count: Int) -> Self {
    operationQueue.maxConcurrentOperationCount = count
    return self
  }
  @discardableResult public func underlyingQueue(_ queue: DispatchQueue) -> Self {
    operationQueue.underlyingQueue = queue
    return self
  }
  @discardableResult public func isSuspended(_ suspended: Bool) -> Self {
    operationQueue.isSuspended = suspended
    return self
  }
  
  // MARK: Private Inits
  private init(operationQueue: OperationQueue) {
    self.operationQueue = operationQueue
  }
  
  // MARK: Public Inits
  public init() {
    operationQueue = .init()
  }
}

extension TaskQueue {
  private struct TaskObserver: Observer {
    private weak var taskQueue: TaskQueue?
    
    internal func task<O1, F1: Error, O2, F2: Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>) {
      taskQueue?.add(newTask)
    }
    internal func taskDidFinish<O, F: Error>(_ task: ProducerTask<O, F>) {
      taskQueue?.tasks[task.id] = nil
    }
    
    internal init(taskQueue: TaskQueue) {
      self.taskQueue = taskQueue
    }
  }
}
