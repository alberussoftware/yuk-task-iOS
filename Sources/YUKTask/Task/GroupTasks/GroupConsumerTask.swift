//
//  GroupConsumerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/5/20.
//

import Combine

import class YUKLock.UnfairLocked
import class Dispatch.DispatchQueue

// MARK: -
open class GroupConsumerProducerTask<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure>, _TaskQueueContainable {
  // MARK: Private Props
  @UnfairLocked
  private var __innerTasks = [AnyProducerTask]()
  @UnfairLocked
  private var __producerTask: Producer!
  
  private lazy var __finishTask = BlockProducerTask<Output, Failure> { [weak self] (_) in
    guard let self = self else { return Empty().eraseToAnyPublisher() }
    return self.producer.publisher
  }
  
  // MARK: Internal Props
  internal final let _taskQueue = TaskQueue().isSuspended(true)
  
  // MARK: Public Typealiases
  public typealias Producer = ProducerTask<Output, Failure>
  
  // MARK: Public Props
  public final var producer: Producer { __producerTask }
  
  // MARK: Public Methods
  public final override func execute(with consumed: Consumed?) -> AnyPublisher<Output, Failure> {
    precondition(__producerTask != nil, "Instantiate with `init(producing:_:)` or `init(producing:) must be accompanied by a mandatory call `set(producer:)` method")
    precondition(!$__innerTasks.read({ $0.contains { $0 === producing || $0 === producer } }), "Inner tasks should not contain `producing` or `producer` tasks")
    
    defer { _taskQueue.isSuspended(false) }
    
    $__innerTasks.read {
      $0.forEach {
        producer.add(dependency: $0)
        _taskQueue.add($0)
      }
    }
    _taskQueue.add(producer)
    
    __finishTask.add(dependency: producer)
    return _taskQueue.add(__finishTask)
  }
  //
  open override func cancel() {
    _taskQueue.cancelAllTasks()
    super.cancel()
  }
  //
  @discardableResult
  public final override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    __finishTask.add(dependency: task)
    return super.produce(new: task)
  }
  //
  public final func set(producer: Producer) {
    precondition(_operation.state < .executing, "`producer` cannot be modified after execution has begun")
    
    __producerTask = producer
  }
  public final func add<O, F: Error>(inner task: ProducerTask<O, F>) {
    precondition(_operation.state < .executing, "Cannot be added inner task after execution has begun")
    
    $__innerTasks.write { $0.append(.init(task)) }
  }
  
  // MARK: Public Inits
  public init(producing: Producing, @AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask], producer: Producer) {
    __producerTask = producer
    __innerTasks = builder()
    super.init(producing: producing)
  }
  public init(producing: Producing, @AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask]) {
    __innerTasks = builder()
    super.init(producing: producing)
  }
  public override init(producing: Producing) {
    super.init(producing: producing)
  }
}

// MARK: -
public typealias GroupConsumerTask<Input, Failure: Error> = GroupConsumerProducerTask<Input, Void, Failure>

// MARK: -
public typealias NonFailGroupConsumerTask<Input> = GroupConsumerTask<Input, Never>

// MARK: -
public typealias NonFailGroupConsumerProducerTask<Input, Output> = GroupConsumerProducerTask<Input, Output, Never>
