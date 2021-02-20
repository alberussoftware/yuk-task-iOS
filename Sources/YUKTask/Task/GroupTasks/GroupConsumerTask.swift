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
  internal final let _innerTasks: [AnyProducerTask]
  
  // MARK: Public Typealiases
  public typealias Producer = ProducerTask<Output, Failure>
  
  // MARK: Public Props
  public final let producer: Producer
  
  // MARK: Public Methods
  public final override func execute(with consumed: Consumed?, and promise: @escaping Promise) {
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
  
  // MARK: Public Inits
  init(producing: Producing, @AnyProducerTaskArrayBuilder _ builder: () -> [AnyProducerTask], producer: Producer) {
    self.producer = producer
    _innerTasks = builder()
    super.init(producing: producing)
    precondition(!_innerTasks.contains { $0 === producing }, "`builder` should not contain `producing` task")
    precondition(!_innerTasks.contains { $0 === producer }, "`builder` should not contain `producer` task")
  }
}

// MARK: -
public typealias GroupConsumerTask<Input, Failure: Error> = GroupConsumerProducerTask<Input, Void, Failure>

// MARK: -
public typealias NonFailGroupConsumerTask<Input> = GroupConsumerTask<Input, Never>

// MARK: -
public typealias NonFailGroupConsumerProducerTask<Input, Output> = GroupConsumerProducerTask<Input, Output, Never>




//
//@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
//open class GroupConsumerProducerTask<Input, Output, Failure: Error>:
//  ConsumerProducerTask<Input, Output, Failure>
//{
//  // MARK:
//  private let lock = UnfairLock()
//
//  // MARK:
//  private let startingTask = EmptyTask()
//  private let finishingTask = EmptyTask()
//
//  // MARK: -
//  // MARK
//  open func setUnderlyingQueue(_ queue: DispatchQueue) -> Self {
//    precondition(_state < .executing, "Cannot modify `underlyingQueue` after execution has begun")
//    innerQueue.underlyingQueue = queue
//    return self
//  }
//
//  // MARK:
//  open override func execute() {
//    innerQueue.isSuspended = false
//    innerQueue.addTask(finishingTask)
//  }
//
//  open override func cancel() {
//    innerQueue.cancelAllTasks()
//    super.cancel()
//  }
//
//  // MARK:
//  open func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {}
//
//  // MARK:
//  open func addTask<T: ProducerTaskProtocol>(_ task: T) {
//    innerQueue.addTask(task)
//  }
//
//  // MARK:
//  public let innerQueue: TaskQueue
//
//  // MARK:
//  public init(
//    name: String? = nil,
//    qos: QualityOfService = .default,
//    priority: Operation.QueuePriority = .normal,
//    underlyingQueue: DispatchQueue? = nil,
//    producing: ProducingTask
//  ) {
//    self.innerQueue = .init(
//      name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//      qos: qos,
//      underlyingQueue: underlyingQueue,
//      startSuspended: true
//    )
//    super.init(name: name, qos: qos, priority: priority, producing: producing)
//    self.innerQueue.delegate = self
//    self.innerQueue.addTask(self.startingTask)
//  }
//
//  public init<T1: ProducerTaskProtocol>(
//    name: String? = nil,
//    qos: QualityOfService = .default,
//    priority: Operation.QueuePriority = .normal,
//    underlyingQueue: DispatchQueue? = nil,
//    producing: ProducingTask,
//    tasks: (T1)
//  ) {
//    self.innerQueue = .init(
//      name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//      qos: qos,
//      underlyingQueue: underlyingQueue,
//      startSuspended: true
//    )
//    super.init(name: name, qos: qos, priority: priority, producing: producing)
//    self.innerQueue.delegate = self
//    self.innerQueue.addTask(self.startingTask)
//    self.innerQueue.addTask(tasks)
//  }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6)
//   ) {
//    self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol, T9: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8, T9)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//     self.innerQueue.addTask(tasks.8)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol, T9: ProducerTaskProtocol, T10: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8, T8, T9, T10)
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//     self.innerQueue.addTask(tasks.8)
//     self.innerQueue.addTask(tasks.9)
//   }
//
//  // MARK:
//  public init<T1: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol, T9: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8, T9),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//     self.innerQueue.addTask(tasks.8)
//   }
//
//   public init<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol, T4: ProducerTaskProtocol, T5: ProducerTaskProtocol, T6: ProducerTaskProtocol, T7: ProducerTaskProtocol, T8: ProducerTaskProtocol, T9: ProducerTaskProtocol, T10: ProducerTaskProtocol>(
//     name: String? = nil,
//     qos: QualityOfService = .default,
//     priority: Operation.QueuePriority = .normal,
//     underlyingQueue: DispatchQueue? = nil,
//     producing: ProducingTask,
//     tasks: (T1, T2, T3, T4, T5, T6, T7, T8, T8, T9, T10),
//     produced: ProducerTask<Output, Failure>
//   ) {
//     self.innerQueue = .init(
//       name: "\(Bundle.main.bundleIdentifier!).\(String(describing: Self.self)).inner",
//       qos: qos,
//       underlyingQueue: underlyingQueue,
//       startSuspended: true
//     )
//     super.init(name: name, qos: qos, priority: priority, producing: producing)
//     produced.recieve { [unowned self] (produced) in self.finish(with: produced) }
//     self.innerQueue.delegate = self
//     self.innerQueue.addTask(self.startingTask)
//     self.innerQueue.addTask(tasks.0)
//     self.innerQueue.addTask(tasks.1)
//     self.innerQueue.addTask(tasks.2)
//     self.innerQueue.addTask(tasks.3)
//     self.innerQueue.addTask(tasks.4)
//     self.innerQueue.addTask(tasks.5)
//     self.innerQueue.addTask(tasks.6)
//     self.innerQueue.addTask(tasks.7)
//     self.innerQueue.addTask(tasks.8)
//     self.innerQueue.addTask(tasks.9)
//   }
//}
//
//// MARK: -
//@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
//extension GroupConsumerProducerTask: TaskQueueDelegate {
//  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, willAdd task: T) {
//    precondition(
//      !finishingTask.isFinished && !finishingTask.isExecuting,
//      "Сannot add new tasks to a group after the group has completed"
//    )
//
//    // Some task in this group has produced a new task to execute.
//    // We want to allow that task to execute before the group completes,
//    // so we'll make the finishing task dependent on this newly-produced task.
//    if task !== finishingTask { finishingTask.addDependency(task) }
//
//    // All tasks should be dependent on the `startingTask`.
//    // This way, we can guarantee that the conditions for other tasks
//    // will not evaluate until just before the task is about to run.
//    // Otherwise, the conditions could be evaluated at any time, even
//    // before the internal operation queue is unsuspended.
//    if task !== startingTask { task.addDependency(startingTask) }
//  }
//
//  public func taskQueue<T: ProducerTaskProtocol>(_ taskQueue: TaskQueue, didFinish task: T) {
//    lock.sync {
//      if task === finishingTask {
//        innerQueue.isSuspended = true
//      }
//      else if task !== startingTask {
//        taskDidFinish(task)
//      }
//    }
//  }
//}
