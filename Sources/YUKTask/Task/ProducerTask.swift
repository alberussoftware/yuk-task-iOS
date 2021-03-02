//
//  ProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/19/20.
//

import class YUKLock.UnfairLock
import class Combine.Future
import class Combine.AnyCancellable
import struct Combine.Published

// MARK: -
open class ProducerTask<Output, Failure: Error>: Identifiable {
  // MARK: Private Props
  private var __operation: _AsyncOperation!
  //
  private var __cancellables = Set<AnyCancellable>()
  //
  private var __conditionTasks = [AnyProducerTask]()
  //
  private var __observers = [Observer]()
  //
  private var __publisher: Future!
  private var __promise: Future.Promise!
  
  // MARK: Internal Prop
  internal let _lock = UnfairLock()
  //
  internal var _operation: _AsyncOperation { __operation }
  //
  internal var _promise: Promise { __promise }
  
  // MARK: Public Typealiases
  public typealias Produced = Result<Output, Failure>
  public typealias Future = Combine.Future<Output, Failure>
  public typealias Promise = Future.Promise
  
  // MARK: Public Props
  public var id: ObjectIdentifier { .init(self) }
  //
  public private(set) var name: String? { didSet { _operation.name = name } }
  public private(set) var qualityOfService = QualityOfService.default { didSet { _operation.qualityOfService = qualityOfService._underline } }
  public private(set) var queuePriority = QueuePriority.normal { didSet { _operation.queuePriority = queuePriority._underline } }
  //
  public var isExecuting: Bool { __operation.isExecuting }
  public var isFinished: Bool { __operation.isFinished }
  public var isCancelled: Bool { __operation.isCancelled }
  //
  public private(set) var produced: Produced?
  //
  public var publisher: Future { __publisher }
  
  // MARK: Public Methods
  open func execute(with promise: @escaping Promise) {
    _abstract()
  }
  open func finishing(with produced: Produced) { }
  open func finished(with produced: Produced) { }
  //
  open func cancel() {
    __operation.cancel()
    __observers.forEach { $0.taskDidCancel(self) }
  }
  //
  public func produce<O, F: Error>(new task: ProducerTask<O, F>) {
    precondition(!isFinished, "Cannot produce new task after task is finished")
    
    _lock.lock()
    defer { _lock.unlock() }
    
    __observers.forEach { $0.task(self, didProduce: task) }
  }
  //
  @discardableResult public func add<C: Condition>(condition: C) -> C.Future {
    precondition(!isFinished && !isExecuting, "Conditions cannot be modified after execution has begun")
    
    _lock.lock()
    defer { _lock.unlock() }
    
    let evaluateTask = BlockTask<C.Failure> { [weak self] (_, promise) in
      guard let self = self else { return }
      condition.evaluate(for: self, with: promise)
    }
    
    let conditionTask: AnyProducerTask
    
    if let dependencyTask = condition.dependency(for: self) {
      conditionTask = .init(GroupTask({ dependencyTask }, producer: evaluateTask))
    }
    else {
      conditionTask = .init(evaluateTask)
    }
    
    if let lastConditionTask = __conditionTasks.last {
      conditionTask.add(dependency: lastConditionTask)
    }
    
    __conditionTasks.append(conditionTask)
   
    return evaluateTask.publisher
  }
  public func add<O: Observer>(observer: O) {
    precondition(!isFinished && !isExecuting, "Observers cannot be modified after execution has begun")
    
    _lock.lock()
    defer { _lock.unlock() }
    
    __observers.append(observer)
  }
  public func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    precondition(!isFinished && !isExecuting, "Dependencies cannot be modified after execution has begun")
    __operation.addDependency(task._operation)
  }
  //
  @discardableResult public func name(_ string: String) -> Self {
    precondition(!isFinished && !isExecuting, "Name cannot be modified after execution has begun")
    name = string
    return self
  }
  @discardableResult public func qualityOfService(_ qos: QualityOfService) -> Self {
    precondition(!isFinished && !isExecuting, "QualityOfService cannot be modified after execution has begun")
    qualityOfService = qos
    return self
  }
  @discardableResult public func queuePriority(_ priority: QueuePriority) -> Self {
    precondition(!isFinished && !isExecuting, "QueuePriority cannot be modified after execution has begun")
    queuePriority = priority
    return self
  }
  
  // MARK: Public Inits
  public init() {
    setupPublisher()
    setupOperation()
  }
}

extension ProducerTask {
  private func setupOperation() {
    __operation = .init(work(_:_:), preparation: preparation(_:_:), finishing: finishing(_:), finished: finished(_:))
    __operation.name = String(describing: Self.self)
  }
  private func setupPublisher() {
    __publisher = .init { [weak self] (promise) in self?.__promise = promise }
  }
}

extension ProducerTask {
  private func preparation(_ op: _AsyncOperation, _ completion: @escaping (Completion) -> Void) {
    if __conditionTasks.isEmpty || isCancelled {
      completion(.finish)
      return
    }
    
    let conditionTasksCount = __conditionTasks.count
    __conditionTasks.lazy
      .enumerated()
      .forEach { (value) in
        value.element
          .publisher
          .sink { [weak self] in
            switch $0 {
            case .finished where value.offset == conditionTasksCount - 1:
              completion(.finish)
              
            case .failure:
              self?.cancel()
              completion(.finish)
              
            default:
              break
            }
          } receiveValue: { (_) in }
          .store(in: &__cancellables)
        
        produce(new: value.element)
      }
  }
  private func work(_ op: _AsyncOperation, _ completion: @escaping (Completion) -> Void) {
    __observers.forEach { $0.taskDidStart(self) }
    execute { (result) in
      self.produced = result
      completion(.finish)
    }
  }
  private func finishing(_ op: _AsyncOperation) {
    guard let produced = produced else { preconditionFailure("Internal inconsistency") }
    finishing(with: produced)
  }
  private func finished(_ op: _AsyncOperation) {
    guard let produced = produced else { preconditionFailure("Internal inconsistency") }
    __promise(produced)
    finished(with: produced)
    __observers.forEach { $0.taskDidFinish(self) }
  }
}

// MARK: -
public typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>

// MARK: -
public typealias Task<Failure: Error> = ProducerTask<Void, Failure>

// MARK: -
public typealias NonFailTask = ProducerTask<Void, Never>
