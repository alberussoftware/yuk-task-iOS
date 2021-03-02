//
//  GroupConsumerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/5/20.
//

import class Dispatch.DispatchQueue
import class Combine.AnyCancellable

// MARK: -
open class GroupConsumerProducerTask<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure> {
  // MARK: Private Props
  private var __cancellable: AnyCancellable?
  
  // MARK: Internal Props
  internal final let _taskQueue = TaskQueue().isSuspended(true)
  internal final private(set) var _innerTasks = [AnyProducerTask]()
  
  // MARK: Public Typealiases
  public typealias Producer = ProducerTask<Output, Failure>
  
  // MARK: Public Props
  public final private(set) var producer: Producer!
  
  // MARK: Public Methods
  public final override func execute(with consumed: Consumed?, and promise: @escaping Promise) {
    precondition(producer != nil, "Instantiate with `init(producing:_:)` or `init(producing:) must be accompanied by a mandatory call `set(producer:)` method")
    precondition(!_innerTasks.contains { $0 === producing || $0 === producer }, "Inner tasks should not contain `producing` or `producer` tasks")
 
    _innerTasks.forEach {
      producer.add(dependency: $0)
      _taskQueue.add($0)
    }
    _taskQueue.add(producer)
    
    __cancellable = producer
      .publisher
      .sink {
        guard case let .failure(error) = $0 else { return }
        promise(.failure(error))
      } receiveValue: {
        promise(.success($0))
      }
    
    _taskQueue.isSuspended(false)
  }
  //
  open override func cancel() {
    _taskQueue.cancelAllTasks()
    super.cancel()
  }
  //
  public final func set(producer: Producer) {
    _lock.lock()
    defer { _lock.unlock() }
    precondition(!isFinished && !isExecuting, "`producer` cannot be modified after execution has begun")
    self.producer = producer
  }
  public final func add<O, F: Error>(inner task: ProducerTask<O, F>) {
    _lock.lock()
    defer { _lock.unlock() }
    precondition(!isFinished && !isExecuting, "Cannot be added inner task after execution has begun")
    _innerTasks.append(.init(task))
  }
  
  // MARK: Public Inits
  init(producing: Producing, @AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask], producer: Producer) {
    self.producer = producer
    _innerTasks = builder()
    super.init(producing: producing)
  }
  init(producing: Producing, @AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask]) {
    _innerTasks = builder()
    super.init(producing: producing)
  }
  override init(producing: Producing) {
    super.init(producing: producing)
  }
}

// MARK: -
public typealias GroupConsumerTask<Input, Failure: Error> = GroupConsumerProducerTask<Input, Void, Failure>

// MARK: -
public typealias NonFailGroupConsumerTask<Input> = GroupConsumerTask<Input, Never>

// MARK: -
public typealias NonFailGroupConsumerProducerTask<Input, Output> = GroupConsumerProducerTask<Input, Output, Never>
