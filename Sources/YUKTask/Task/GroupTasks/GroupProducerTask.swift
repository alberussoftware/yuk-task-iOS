//
//  GroupProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/5/20.
//

import Foundation
import Combine
import YUKLock

// MARK: -
open class GroupProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure>, TaskQueueContainable {
  // MARK: Private Props
  @UnfairLocked private var innerTasks = [AnyProducerTask]()
  @UnfairLocked private var producerTask: Producer!
  //
  private lazy var finishTask = BlockProducerTask<Output, Failure> { [weak self] (_) in
    guard let self = self else { return Empty().eraseToAnyPublisher() }
    return self.producer.publisher
  }
  
  // MARK: Internal Props
  internal final let taskQueue = TaskQueue().isSuspended(true)
  
  // MARK: Public Typealiases
  public typealias Producer = ProducerTask<Output, Failure>
  
  // MARK: Public Props
  public final var producer: Producer { producerTask }
  
  // MARK: Public Methods
  public final override func execute() -> AnyPublisher<Output, Failure> {
    precondition(producerTask != nil, "Instantiate with `init(_:)` or `init() must be accompanied by a mandatory call `set(producer:)` method")
    precondition(!$innerTasks.read({ $0.contains { $0 === producer } }), "Inner tasks should not contain `producer` task")
    
    defer { taskQueue.isSuspended(false) }
    
    $innerTasks.read {
      $0.forEach {
        producer.add(dependency: $0)
        taskQueue.add($0)
      }
    }
    taskQueue.add(producer)
    
    finishTask.add(dependency: producer)
    
    return taskQueue.add(finishTask)
  }
  //
  open override func cancel() {
    taskQueue.cancelAllTasks()
    
    super.cancel()
  }
  //
  @discardableResult public final override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    finishTask.add(dependency: task)
    return super.produce(new: task)
  }
  //
  public final func set(producer: Producer) {
    precondition(operation.state < .executing, "`producer` cannot be modified after execution has begun")
    
    producerTask = producer
  }
  public final func add<O, F: Error>(inner task: ProducerTask<O, F>) {
    precondition(operation.state < .executing, "Cannot be added inner task after execution has begun")
    
    $innerTasks.write { $0.append(.init(task)) }
  }
  
  // MARK: Public Inits
  public init(@AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask], producer: Producer) {
    producerTask = producer
    innerTasks = builder()
    super.init()
  }
  public init(@AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask]) {
    innerTasks = builder()
    super.init()
  }
  public override init() {
    super.init()
  }
}

// MARK: -
public typealias GroupTask<Failure: Error> = GroupProducerTask<Void, Failure>

// MARK: -
public typealias NonFailGroupTask = GroupTask<Never>

// MARK: -
public typealias NonFailGroupProducerTask<Output> = GroupProducerTask<Output, Never>
