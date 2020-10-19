//
//  TaskQueue.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/3/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol TaskQueueDelegate: AnyObject {  
  func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T)
  
  func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T)
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension TaskQueueDelegate {
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T) {}
  
  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T) {}
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol TaskQueueContainable: Operation {
  var innerQueue: TaskQueue { get }
}


internal struct _TaskQueueDelegateObserver {
  // MARK:
  private unowned let taskQueue: TaskQueue
  
  // MARK: - API
  // MARK:
  internal init(taskQueue: TaskQueue) {
    self.taskQueue = taskQueue
  }
}

// MARK: -
extension _TaskQueueDelegateObserver: Observer {
  internal func task<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(_ task: T1, didProduce newTask: T2) {
    taskQueue.addTask(newTask)
  }
  
  internal func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
    taskQueue.delegate?.taskQueue(taskQueue, didFinish: task)
  }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
open class TaskQueue: OperationQueue {
  // MARK:
  @available(*, unavailable)
  open override var maxConcurrentOperationCount: Int {
    didSet {}
  }
  
  // MARK:
  @available(*, unavailable)
  open override func addOperation(_ operation: Operation) {
    super.addOperation(operation)
  }
  
  @available(*, unavailable)
  open override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
    super.addOperations(operations, waitUntilFinished: wait)
  }
  
  @available(*, unavailable)
  open override func addOperation(_ block: @escaping () -> Void) {
    super.addOperation(block)
  }
  
  // MARK:
  @available(*, unavailable)
  open override func waitUntilAllOperationsAreFinished() {
    super.waitUntilAllOperationsAreFinished()
  }
  
  // MARK:
  @available(*, unavailable)
  open override func cancelAllOperations() {
    super.cancelAllOperations()
  }
  
  // MARK:
  @available(*, unavailable)
  public override init() {
    super.init()
  }
  
  // MARK: - API
  // MARK:
  open func addTask<T: ProducerTaskProtocol>(_ task: T) {
    // Set up a observer to invoke the `OperationQueueDelegate` methods.
    task.addObserver(_TaskQueueDelegateObserver(taskQueue: self))
    
    // Extract any dependencies needed by this operation.
    task
      .conditions
      .lazy
      .compactMap { $0.dependency(for: task) }
      .forEach {
        task.addDependency($0)
        super.addOperation($0)
      }
    
    // With condition dependencies added, we can now see if this needs
    // dependencies to enforce mutual exclusivity.
    let categories =
      task
        .mutuallyExclusiveConditions
        .map { $0.key }
    
    if !categories.isEmpty {
      // Set up the mutual exclusivity dependencies.
      _ConditionMutuallyExclusivityController.shared.add(task, forCategories: categories)
      task.addObserver(_ConditionMutuallyExclusivityObserver(categories: categories))
    }
    
    // Indicate to the operation that we've finished our extra work on it
    // and it's now it a state where it can proceed with evaluating conditions, if appropriate.
    task.willEnqueue()
    
    self.delegate?.taskQueue(self, willAdd: task)
    
    super.addOperation(task)
  }
  
  open func addTaskAfter<T: ProducerTaskProtocol>(_ task: T, deadline: DispatchTime) {
    DispatchQueue.global().asyncAfter(deadline: deadline) { self.addTask(task) }
  }

  open func addBlock(_ block: @escaping () -> Void) { super.addOperation(block) }
  
  open override func addBarrierBlock(_ block: @escaping () -> Void) { super.addBarrierBlock(block) }
  
  // MARK:
  open func waitUntilAllTasksAreFinished() { super.waitUntilAllOperationsAreFinished() }
  
  // MARK:
  open func cancelAllTasks() { super.cancelAllOperations() }
  
  // MARK:
  open weak var delegate: TaskQueueDelegate?
  open var maxConcurrentTaskCount: Int {
    get { super.maxConcurrentOperationCount }
    set { super.maxConcurrentOperationCount = newValue }
  }
  
  // MARK:
  @inlinable
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    maxConcurrentTasks: Int = OperationQueue.defaultMaxConcurrentOperationCount,
    underlyingQueue: DispatchQueue? = nil,
    startSuspended: Bool = false
  ) {
    super.init()
    self.name = name
    qualityOfService = qos
    maxConcurrentTaskCount = maxConcurrentTasks
    self.underlyingQueue = underlyingQueue
    isSuspended = startSuspended
  }
}
