//
//  ProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/19/20.
//

import Combine
import YUKLock

// MARK: -
open class ProducerTask<Output, Failure: Error>: Identifiable {
  // MARK: Private Props
  private var _operation: AsyncOperation!
  //
  @UnfairLocked
  private var conditionTasks = [AnyProducerTask]()
  //
  @UnfairLocked
  private var observers = [Observer]()
  //
  private var _publisher: AnyPublisher<Output, Failure>!
  private var _promise: Future<Output, Failure>.Promise!
  
  // MARK: Internal Prop
  internal var operation: AsyncOperation { _operation }
  //
  internal var promise: Future<Output, Failure>.Promise { _promise }
  
  // MARK: Public Typealiases
  public typealias Produced = Result<Output, Failure>
  
  // MARK: Public Props
  public var id: ObjectIdentifier { .init(self) }
  //
  public var name: String? { operation.name }
  public var qualityOfService: QualityOfService {  .init(operation.qualityOfService)  }
  public var queuePriority: QueuePriority { .init(operation.queuePriority)  }
  //
  public var isExecuting: Bool { _operation.isExecuting }
  public var isFinished: Bool { _operation.isFinished }
  public var isCancelled: Bool { _operation.isCancelled }
  //
  public private(set) var produced: Produced?
  //
  public var publisher: AnyPublisher<Output, Failure> { _publisher }
  
  // MARK: Public Methods
  open func execute() -> AnyPublisher<Output, Failure> {
    _abstract()
  }
  open func finishing(with produced: Produced) -> AnyPublisher<Void, Never> {
    Result.Publisher(.success).eraseToAnyPublisher()
  }
  open func finished(with produced: Produced) {
    
  }
  //
  open func cancel() {
    _operation.cancel()
    $observers.read { $0.forEach { $0.taskDidCancel(self) } }
  }
  //
  @discardableResult public func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    precondition((.pending)...(.executing) ~= operation.state , "Cannot produce new task after task is executing or before added to the queue")
    
    $observers.read { $0.forEach { $0.task(self, didProduce: task) } }
    
    return task.publisher
  }
  //
  @discardableResult public func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    precondition(operation.state < .pending, "Conditions cannot be modified after task added to the queue")
    
    let evaluateTask = BlockTask<C.Failure> { [weak self] (_) in
      guard let self = self else { return Result.Publisher(.success).eraseToAnyPublisher() }
      return condition.evaluate(for: self)
    }
    
    let conditionTask: AnyProducerTask
    if let dependencyTask = condition.dependency(for: self) {
      conditionTask = .init(GroupTask({ dependencyTask }, producer: evaluateTask))
    }
    else {
      conditionTask = .init(evaluateTask)
    }
    
    if let lastConditionTask = $conditionTasks.read({ $0.last }) {
      conditionTask.add(dependency: lastConditionTask)
    }
    $conditionTasks.write { $0.append(conditionTask) }
    
    return evaluateTask.publisher
  }
  public func add<O: Observer>(observer: O) {
    precondition(operation.state < .executing, "Observers cannot be modified after task execution has begun")
    
    $observers.write { $0.append(observer) }
  }
  public func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    precondition(operation.state < .executing, "Dependencies cannot be modified after task execution has begun")
    
    _operation.addDependency(task.operation)
  }
  //
  @discardableResult public func name(_ string: String) -> Self {
    precondition(operation.state < .pending, "Name cannot be modified after task added to the queue")
    
    operation.name = string
    
    return self
  }
  @discardableResult public func qualityOfService(_ qos: QualityOfService) -> Self {
    precondition(operation.state < .pending, "QualityOfService cannot be modified after task added to the queue")
    
    operation.qualityOfService  = qos._underline
    
    return self
  }
  @discardableResult public func queuePriority(_ priority: QueuePriority) -> Self {
    precondition(operation.state < .pending, "QueuePriority cannot be modified aftertask added to the queue")
    
    operation.queuePriority = priority._underline
    
    return self
  }
  //
  public final func eraseToAnyProducerTask() -> AnyProducerTask {
    .init(self)
  }
  
  // MARK: Public Inits
  public init() {
    _operation = .init { [weak self] (_) in
      guard let self = self else { return Result.Publisher(.success).eraseToAnyPublisher() }
      
      if self.$conditionTasks.read({ $0.isEmpty }) || self.isCancelled { return Result.Publisher(.success).eraseToAnyPublisher() }
      
      return Publishers
        .MergeMany(self.$conditionTasks.read { $0.lazy.map { self.produce(new: $0) } })
        .eraseOutputToVoid()
        .catch { (_) -> AnyPublisher<Void, Never> in
          self.cancel()
          return Result.Publisher(.success).eraseToAnyPublisher()
        }
        .collect()
        .eraseOutputToVoid()
      
    } work: { [weak self] (_) in
      guard let self = self else { return Result.Publisher(.success).eraseToAnyPublisher() }
      
      self.$observers.read { $0.forEach { $0.taskDidStart(self) } }
      
      return self.execute()
        .map { (value) -> Void in
          self.produced = .success(value)
          return ()
        }
        .catch { (error) -> AnyPublisher<Void, Never> in
          self.produced = .failure(error)
          return Just(()).eraseToAnyPublisher()
        }
        .eraseOutputToVoid()
      
    } onFinishing: { [weak self] (_) in
      guard let self = self else { return Result.Publisher(.success).eraseToAnyPublisher() }
      
      guard let produced = self.produced else { preconditionFailure("Internal inconsistency") }
      
      return self.finishing(with: produced)
        .eraseToAnyPublisher()
      
    } onFinished: { [weak self] (_) in
      guard let self = self else { return }
      
      guard let produced = self.produced else { preconditionFailure("Internal inconsistency") }
      
      self._promise(produced)
      
      self.$observers.read { $0.forEach { $0.taskDidFinish(self) } }
      
      self.finished(with: produced)
    }
    _operation.name = String(describing: Self.self)
    _publisher = Future { [weak self] (promise) in self?._promise = promise }.eraseToAnyPublisher()
  }
}

// MARK: -
public typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>

// MARK: -
public typealias Task<Failure: Error> = ProducerTask<Void, Failure>

// MARK: -
public typealias NonFailTask = ProducerTask<Void, Never>
