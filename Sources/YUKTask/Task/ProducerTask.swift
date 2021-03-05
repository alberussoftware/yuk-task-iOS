//
//  ProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/19/20.
//

import YUKLock
import Combine

// MARK: -
open class ProducerTask<Output, Failure: Error>: Identifiable {
  // MARK: Private Props
  private var __operation: _AsyncOperation!
  //
  @UnfairLocked
  private var __conditionTasks = [AnyProducerTask]()
  //
  @UnfairLocked
  private var __observers = [Observer]()
  //
  private var __publisher: AnyPublisher<Output, Failure>!
  private var __promise: Future<Output, Failure>.Promise!
  
  // MARK: Internal Prop
  internal var _operation: _AsyncOperation { __operation }
  //
  internal var _promise: Future<Output, Failure>.Promise { __promise }
  
  // MARK: Public Typealiases
  public typealias Produced = Result<Output, Failure>
  
  // MARK: Public Props
  public var id: ObjectIdentifier { .init(self) }
  //
  public var name: String? { _operation.name }
  public var qualityOfService: QualityOfService {  .init(_operation.qualityOfService)  }
  public var queuePriority: QueuePriority { .init(_operation.queuePriority)  }
  //
  public var isExecuting: Bool { __operation.isExecuting }
  public var isFinished: Bool { __operation.isFinished }
  public var isCancelled: Bool { __operation.isCancelled }
  //
  public private(set) var produced: Produced?
  //
  public var publisher: AnyPublisher<Output, Failure> { __publisher }
  
  // MARK: Public Methods
  open func execute() -> AnyPublisher<Output, Failure> {
    _abstract()
  }
  open func finishing(with produced: Produced) -> AnyPublisher<Void, Never> {
    Just(()).eraseToAnyPublisher()
  }
  open func finished(with produced: Produced) { }
  //
  open func cancel() {
    __operation.cancel()
    $__observers.read { $0.forEach { $0.taskDidCancel(self) } }
  }
  //
  @discardableResult
  public func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    precondition((.pending)...(.executing) ~= _operation.state , "Cannot produce new task after task is executing or before added to the queue")
    
    $__observers.read { $0.forEach { $0.task(self, didProduce: task) } }
    
    return task.publisher
  }
  //
  @discardableResult
  public func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    precondition(_operation.state < .pending, "Conditions cannot be modified after task added to the queue")
    
    let evaluateTask = BlockTask<C.Failure> { [weak self] (_) in
      guard let self = self else { return Empty().eraseToAnyPublisher() }
      return condition.evaluate(for: self)
    }
    
    let conditionTask: AnyProducerTask
    if let dependencyTask = condition.dependency(for: self) {
      conditionTask = .init(GroupTask({ dependencyTask }, producer: evaluateTask))
    }
    else {
      conditionTask = .init(evaluateTask)
    }
    
    if let lastConditionTask = $__conditionTasks.read({ $0.last }) {
      conditionTask.add(dependency: lastConditionTask)
    }
    $__conditionTasks.write { $0.append(conditionTask) }
   
    return evaluateTask.publisher
  }
  
  public func add<O: Observer>(observer: O) {
    precondition(_operation.state < .executing, "Observers cannot be modified after task execution has begun")
    
    $__observers.write { $0.append(observer) }
  }
  public func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    precondition(_operation.state < .executing, "Dependencies cannot be modified after task execution has begun")
    
    __operation.addDependency(task._operation)
  }
  //
  @discardableResult
  public func name(_ string: String) -> Self {
    precondition(_operation.state < .pending, "Name cannot be modified after task added to the queue")
    
    _operation.name = string
    return self
  }
  @discardableResult
  public func qualityOfService(_ qos: QualityOfService) -> Self {
    precondition(_operation.state < .pending, "QualityOfService cannot be modified after task added to the queue")
    
    _operation.qualityOfService  = qos._underline
    return self
  }
  @discardableResult
  public func queuePriority(_ priority: QueuePriority) -> Self {
    precondition(_operation.state < .pending, "QueuePriority cannot be modified aftertask added to the queue")
    
    _operation.queuePriority = priority._underline
    return self
  }
  //
  public final func eraseToAnyProducerTask() -> AnyProducerTask {
    .init(self)
  }
  
  // MARK: Public Inits
  public init() {
    __operation = .init(preparation: preparation(_:), work: work(_:), finishing: finishing(_:), finished: finished(_:))
    __operation.name = String(describing: Self.self)
    __publisher = Future { [weak self] (promise) in self?.__promise = promise }.eraseToAnyPublisher()
  }
}
extension ProducerTask {
  private func preparation(_ op: _AsyncOperation) -> AnyPublisher<Void, Never> {
    if $__conditionTasks.read({ $0.isEmpty }) || isCancelled { return Just(()).eraseToAnyPublisher() }
    
    return Publishers.MergeMany($__conditionTasks.read { $0.lazy.map { self.produce(new: $0) } })
      .map { (_) in () }
      .catch { (_) -> AnyPublisher<Void, Never> in
        self.cancel()
        return Just(()).eraseToAnyPublisher()
      }
      .collect()
      .flatMap { (_) in Just(()).eraseToAnyPublisher() }
      .eraseToAnyPublisher()
  }
  private func work(_ op: _AsyncOperation) -> AnyPublisher<Void, Never> {
    $__observers.read { $0.forEach { $0.taskDidStart(self) } }
    return execute()
      .first()
      .map { (value) -> Void in
        self.produced = .success(value)
        return ()
      }
      .catch { (error) -> AnyPublisher<Void, Never> in
        self.produced = .failure(error)
        return Just(()).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  private func finishing(_ op: _AsyncOperation) -> AnyPublisher<Void, Never> {
    guard let produced = produced else { preconditionFailure("Internal inconsistency") }
    return finishing(with: produced)
      .first()
      .eraseToAnyPublisher()
  }
  private func finished(_ op: _AsyncOperation) {
    guard let produced = produced else { preconditionFailure("Internal inconsistency") }
    __promise(produced)
    $__observers.read { $0.forEach { $0.taskDidFinish(self) } }
    finished(with: produced)
  }
}

// MARK: -
public typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>

// MARK: -
public typealias Task<Failure: Error> = ProducerTask<Void, Failure>

// MARK: -
public typealias NonFailTask = ProducerTask<Void, Never>
