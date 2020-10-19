//
//  ProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 10/19/20.
//

import Foundation
import YUKLock

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias Task<Failure: Error> = ProducerTask<Void, Failure>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Result where Success == Void {
  public static var success: Self {
    .success(())
  }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailTask = ProducerTask<Void, Never>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailProducerTask<Output> = ProducerTask<Output, Never>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum ProducerTaskError: Error {
  case conditionsFailure(_ errors: [Error])
  case executionFailure
}


@inline(never)
@usableFromInline
internal func _abstract(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError("\(function) must be overridden.", file: file, line: line)
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
open class ProducerTask<Output, Failure: Error>: Operation, ProducerTaskProtocol {
  // MARK:
  private static var keyPathsForValuesAffectings: Set<String> {
    ["state"]
  }
  @objc
  private static func keyPathsForValuesAffectingIsReady() -> Set<String> {
    Self.keyPathsForValuesAffectings
  }
  @objc
  private static func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
    Self.keyPathsForValuesAffectings
  }
  @objc
  private static func keyPathsForValuesAffectingIsFinished() -> Set<String> {
    Self.keyPathsForValuesAffectings
  }
  
  // MARK:
  private let stateLock = UnfairLock()
  private var _state = _State.initialized
  internal private(set) var state: _State {
    get {
      stateLock.sync { _state }
    }
    set(newState) {
      // It's important to note that the KVO notifications are NOT called from inside
      // the lock. If they were, the app would deadlock, because in the middle of
      // calling the `didChangeValueForKey()` method, the observers try to access
      // properties like `isReady` or `isFinished`. Since those methods also
      // acquire the lock, then we'd be stuck waiting on our own lock. It's the
      // classic definition of deadlock.
      willChangeValue(forKey: "state")
      stateLock.sync {
        guard _state != .finished else { return }
        precondition(_state.canTransition(to: newState), "Performing invalid state transition")
        _state = newState
      }
      didChangeValue(forKey: "state")
    }
  }
  
  // MARK: -
  private func evaluateConditions() {
    precondition(state == .pending, "\(#function) was called out-of-order")

    state = .evaluatingConditions

    _ConditionEvaluator.shared.evaluate(conditions, for: self) { (results) in
      let errors =
        results
        .compactMap { (result) -> Swift.Error? in
          if case let .failure(error) = result {
            return error
          } else {
            return nil
          }
        }

      if !errors.isEmpty { self.produced = .failure(.internal(ProducerTaskError.conditionsFailure(errors))) }

      self.state = .ready
    }
  }
  
  // MARK:
  private var hasFinishedAlready = false
    
  // MARK:
  private unowned(unsafe) var recieveQueue: DispatchQueue?
  
  // MARK:
  @available(*, unavailable)
  open override var completionBlock: (() -> Void)? {
    didSet {}
  }
  private var producedCompletionBlock: ((Produced) -> Void)?
  private var assignBlock: ((Output) -> Void)?
  
  // MARK:
  @available(*, unavailable)
  public override init() {
    super.init()
  }
  
  // MARK: - API
  // MARK:
  public typealias Output = Output
  public typealias Failure = Failure
  
  // MARK:
  @discardableResult
  open func addCondition<C: Condition>(_ condition: C) -> Self {
    precondition(state < .pending, "Cannot modify conditions after execution has begun")
    conditions.append(.init(condition))
    return self
  }
  
  @discardableResult
  open func addCondition<T>(_ condition: Conditions.MutuallyExclusive<T>) -> Self {
    precondition(state < .pending, "Cannot modify conditions after execution has begun")
    mutuallyExclusiveConditions[String(describing: T.self)] = .init(condition)
    conditions.append(.init(condition))
    return self
  }
  
  // MARK:
  @discardableResult
  open func addObserver<O: Observer>(_ observer: O) -> Self {
    precondition(state < .executing, "Cannot modify observers after execution has begun")
    observers.append(observer)
    return self
  }
  
  // MARK:
  open func willEnqueue() {
    precondition(state != .ready, "You should not call the `cancel()` method before adding to the queue")
    state = .pending
  }
  
  open override func start() {
    // `Operation.start()` method contains important logic that shouldn't be bypassed.
    super.start()
    // If the operation has been cancelled, we still need to enter the `.finished` state.
    if isCancelled { finish(with: produced ?? .failure(.internal(ProducerTaskError.executionFailure))) }
  }
  
  open override func cancel() {
    super.cancel()
    observers.forEach { $0.taskDidCancel(self) }
  }
  
  open override func main() {
    precondition(state == .ready, "This task must be performed on an task queue")
    
    if produced == nil && !isCancelled {
      state = .executing
      observers.forEach { $0.taskDidStart(self) }
      execute()
    }
    else {
      finish(with: produced ?? .failure(.internal(ProducerTaskError.executionFailure)))
    }
  }
  
  // MARK:
  open func execute() {
    _abstract()
  }
  
  // MARK:
  open func produce<T: ProducerTaskProtocol>(new task: T) {
    observers.forEach { $0.task(self, didProduce: task) }
  }
  
  // MARK:
  open func finish(with produced: Produced) {
    if !hasFinishedAlready {
      self.produced = produced
      hasFinishedAlready = true
      state = .finishing
      let block = {
        self.producedCompletionBlock?(produced)
        if case let .success(value) = produced { self.assignBlock?(value) }
      }
      if let recieveQueue = recieveQueue {
        recieveQueue.async { block() }
      }
      else {
        block()
      }
      finished(with: produced)
      observers.forEach { $0.taskDidFinish(self) }
      state = .finished
    }
  }
  
  open func finished(with produced: Produced) {}
  
  public final override func waitUntilFinished() {
    super.waitUntilFinished()
  }
  
  // MARK:
  @available(*, unavailable)
  open override func addDependency(_ operation: Operation) {
    super.addDependency(operation)
  }
  
  @available(*, unavailable)
  open override func removeDependency(_ operation: Operation) {
    super.removeDependency(operation)
  }
  
  @discardableResult
  open func addDependency<T: ProducerTaskProtocol>(_ task: T) -> Self {
    precondition(state < .executing, "Dependencies cannot be modified after execution has begun")
    super.addDependency(task)
    return self
  }
  
  @discardableResult
  open func removeDependency<T: ProducerTaskProtocol>(_ task: T) -> Self {
    precondition(state < .executing, "Dependencies cannot be modified after execution has begun")
    super.removeDependency(task)
    return self
  }
  
  // MARK:
  @discardableResult
  open func recieve(on queue: DispatchQueue) -> Self {
    recieveQueue = queue
    return self
  }
  
  // MARK:
  @discardableResult
  open func recieve(completion: @escaping (Produced) -> Void) -> Self {
    if let existing = producedCompletionBlock {
      producedCompletionBlock = {
        existing($0)
        completion($0)
      }
    }
    else {
      producedCompletionBlock = completion
    }
    return self
  }
  
  @discardableResult
  open func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Self {
    let block: (Output) -> Void = { object[keyPath: keyPath] = $0 }
    if let existing = assignBlock {
      assignBlock = {
        existing($0)
        block($0)
      }
    }
    else {
      assignBlock = block
    }
    return self
  }
  
  // MARK:
  open private(set) var produced: Produced?
  open private(set) var mutuallyExclusiveConditions = [String : AnyCondition]()
  open private(set) var conditions = [AnyCondition]()
  open private(set) var observers = [Observer]()
  open override var isReady: Bool {
    switch state {
    case .initialized:
      if isCancelled { state = .pending }
      return false
    case .pending:
      evaluateConditions()
      // Until conditions have been evaluated, `isReady` returns false
      return false
    case .ready:
      return super.isReady || isCancelled
    default:
      return false
    }
  }
  open override var isExecuting: Bool {
    state == .executing
  }
  open override var isFinished: Bool {
    state == .finished
  }
  
  // MARK:
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal
  ) {
    super.init()
    self.name = name ?? String(describing: Self.self)
    self.qualityOfService = qos
    self.queuePriority = priority
  }
}

// MARK: -
extension ProducerTask {
  
internal enum _State: Int {
  case initialized
  case pending
  case evaluatingConditions
  case ready
  case executing
  case finishing
  case finished
  
  func canTransition(to newState: Self) -> Bool {
    switch (self, newState) {
    case (.initialized, .pending),
         (.pending, .evaluatingConditions),
         (.evaluatingConditions, .ready),
         (.ready, .executing),
         (.ready, .finishing),
         (.executing, .finishing),
         (.finishing, .finished):
      return true
    default:
      return false
    }
  }
}
  
}

// MARK: -
extension ProducerTask._State: Comparable {
  internal static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
  
  internal static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func map<NewOutput>(
    _ transform: @escaping (Output) -> NewOutput
  ) -> Tasks.Map<Output, NewOutput, Failure>
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func tryMap<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput
  ) -> Tasks.TryMap<Output, NewOutput, Failure>
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func flatMap<T: ProducerTaskProtocol>(
    _ transform: @escaping (Output) -> T
  ) -> Tasks.FlatMap<Output, Failure, T> where T.Output == Output, T.Failure == Failure
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func mapError<NewFailure: Swift.Error>(
    _ transform: @escaping (Failure) -> NewFailure
  ) -> Tasks.MapError<Output, Failure, NewFailure>
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func replaceNil<NonNilOutput>(
    with output: @escaping () -> NonNilOutput
  ) -> Tasks.Map<Output, NonNilOutput, Failure> where Output == NonNilOutput?
  { .init(from: self, transform: { _ in output() }) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Failure == Never {
  @inlinable
  public func setFailureType<NewFailure: Swift.Error>(
    to failureType: NewFailure.Type
  ) -> Tasks.SetFailureType<Output, NewFailure>
  { .init(from: self) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func compactMap<NewOutput>(
    _ transform: @escaping (Output) -> NewOutput?
  ) -> Tasks.CompactMap<Output, NewOutput, Failure>
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func tryCompactMap<NewOutput>(
    _ transform: @escaping (Output) throws -> NewOutput?
  ) -> Tasks.TryCompactMap<Output, NewOutput, Failure>
  { .init(from: self, transform: transform) }
  
  @inlinable
  public func replaceError(
    with output: @escaping (Failure) -> Output
  ) -> Tasks.ReplaceError<Output, Failure>
  { .init(from: self, with: output) }
  
  @inlinable
  public func ignoreOutput() -> Tasks.IgnoreOutput<Output, Failure> {
    .init(from: self)
  }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Void {
  @inlinable
  public func replaceEmpty<NewOutput>(
    with output: @escaping () -> NewOutput
  ) -> Tasks.ReplaceEmpty<NewOutput, Failure>
  { .init(from: self, with: output) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func zip<
    T: ProducerTaskProtocol
  >(
    _ t: T
  ) -> Tasks.Zip<ProducerTask, T>
  where Failure == T.Failure
  { .init(tasks: (self, t)) }
  
  @inlinable
  public func zip<
    T1: ProducerTaskProtocol,
    T2: ProducerTaskProtocol
  >(
    _ t1: T1,
    _ t2: T2
  ) -> Tasks.Zip3<ProducerTask, T1, T2>
    where Failure == T1.Failure,
          T1.Failure == T2.Failure
  { .init(tasks: (self, t1, t2)) }
  
  @inlinable
  public func zip<
    T1: ProducerTaskProtocol,
    T2: ProducerTaskProtocol,
    T3: ProducerTaskProtocol
  >(
    _ t1: T1,
    _ t2: T2,
    _ t3: T3
  ) -> Tasks.Zip4<ProducerTask, T1, T2, T3>
  where Failure == T1.Failure,
        T1.Failure == T2.Failure,
        T2.Failure == T3.Failure
  { .init(tasks: (self, t1, t2, t3)) }
  
  @inlinable
  public func zip<
    T1: ProducerTaskProtocol,
    T2: ProducerTaskProtocol,
    T3: ProducerTaskProtocol,
    T4: ProducerTaskProtocol
  >(
    _ t1: T1,
    _ t2: T2,
    _ t3: T3,
    _ t4: T4
  ) -> Tasks.Zip5<ProducerTask, T1, T2, T3, T4>
  where Failure == T1.Failure,
        T1.Failure == T2.Failure,
        T2.Failure == T3.Failure,
        T3.Failure == T4.Failure
  { .init(tasks: (self, t1, t2, t3, t4)) }
  
  @inlinable
  public func zip<
    T1: ProducerTaskProtocol,
    T2: ProducerTaskProtocol,
    T3: ProducerTaskProtocol,
    T4: ProducerTaskProtocol,
    T5: ProducerTaskProtocol
  >(
    _ t1: T1,
    _ t2: T2,
    _ t3: T3,
    _ t4: T4,
    _ t5: T5
  ) -> Tasks.Zip6<ProducerTask, T1, T2, T3, T4, T5>
  where Failure == T1.Failure,
        T1.Failure == T2.Failure,
        T2.Failure == T3.Failure,
        T3.Failure == T4.Failure,
        T4.Failure == T5.Failure
  { .init(tasks: (self, t1, t2, t3, t4, t5)) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func assertNoFailure(
  _ prefix: String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) -> Tasks.AssertNoFailure<Output, Failure>
  { .init(prefix, file: file, line: line, from: self) }
  
  @inlinable
  public func `catch`<T: ProducerTaskProtocol>(
    _ handler: @escaping (Failure) -> T
  ) -> Tasks.Catch<Output, Failure, T> where T.Output == Output
  { .init(from: self, handler: handler) }
  
  @inlinable
  public func tryCatch<T: ProducerTaskProtocol>(
    _ handler: @escaping (Failure) throws -> T
  ) -> Tasks.TryCatch<Output, Failure, T> where T.Output == Output
  { .init(from: self, handler: handler) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Data {
  @inlinable
  public func decode<Item: Decodable>(
    type: Item.Type,
    decoder: JSONDecoder
  ) -> Tasks.Decode<Failure, Item>
  { .init(from: self, type: type, decoder: decoder) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output: Encodable {
  @inlinable
  public func encode(
    encoder: JSONEncoder
  ) -> Tasks.Encode<Output, Failure>
  { .init(from: self, encoder: encoder) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func map<NewOutput>(
    _ keyPath: KeyPath<Output, NewOutput>
  ) -> Tasks.MapKeyPath<Output, NewOutput, Failure>
  { .init(from: self, keyPath: keyPath) }
  
  @inlinable
  public func map<NewOutput1, NewOutput2>(
    _ keyPath1: KeyPath<Output, NewOutput1>,
    _ keyPath2: KeyPath<Output, NewOutput2>
  ) -> Tasks.MapKeyPath2<Output, NewOutput1, NewOutput2, Failure>
  { .init(from: self, keyPath1: keyPath1, keyPath2: keyPath2) }
  
  @inlinable
  public func map<NewOutput1, NewOutput2, NewOutput3>(
    _ keyPath1: KeyPath<Output, NewOutput1>,
    _ keyPath2: KeyPath<Output, NewOutput2>,
    _ keyPath3: KeyPath<Output, NewOutput3>
  ) -> Tasks.MapKeyPath3<Output, NewOutput1, NewOutput2, NewOutput3, Failure>
  { .init(from: self, keyPath1: keyPath1, keyPath2: keyPath2, keyPath3: keyPath3) }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Output == Void  {
  @inlinable
  public func breakpointOnOutput(
    receiveOutput: @escaping (Output) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure>
  { fatalError("Can't call when Output == Void") }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask where Failure == Never  {
  @inlinable
  public func breakpointOnFailure(
    receiveFailure: @escaping (Failure) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure>
  { fatalError("Can't call when Failure == Never") }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension ProducerTask {
  @inlinable
  public func breakpointOnOutput(
    receiveOutput: @escaping (Output) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure>
  { .init(from: self, receiveOutput: receiveOutput, receiveFailure: nil) }
  
  @inlinable
  public func breakpointOnFailure(
    receiveFailure: @escaping (Failure) -> Bool
  ) -> Tasks.BreakpointTask<Output, Failure>
  { .init(from: self, receiveOutput: nil, receiveFailure: receiveFailure) }

  @inlinable
  public func breakpointOnError() -> Tasks.BreakpointTask<Output, Failure> {
    .init(from: self, receiveOutput: nil, receiveFailure: nil)
  }
}
