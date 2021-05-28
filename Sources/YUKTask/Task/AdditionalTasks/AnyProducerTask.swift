//
//  AnyProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/14/21.
//

import Combine

// MARK: -
@usableFromInline
internal class AnyProducerTaskBox {
  internal var operation: AsyncOperation { _abstract() }
  //
  @inlinable internal var promise: Future<Any, Error>.Promise { _abstract() }
  
  @inlinable internal var name: String? { _abstract() }
  @inlinable internal var qualityOfService: QualityOfService { _abstract() }
  @inlinable internal var queuePriority: QueuePriority { _abstract() }
  //
  @inlinable internal var isExecuting: Bool { _abstract() }
  @inlinable internal var isFinished: Bool { _abstract() }
  @inlinable internal var isCancelled: Bool { _abstract() }
  //
  @inlinable internal var produced: Result<Any, Error>? { _abstract() }
  //
  @inlinable internal var publisher: AnyPublisher<Any, Error> { _abstract() }

  @inlinable internal func execute() -> AnyPublisher<Any, Error> {
    _abstract()
  }
  @inlinable internal func finishing(with produced: Result<Any, Error>) -> AnyPublisher<Void, Never> {
    _abstract()
  }
  @inlinable internal func finished(with produced: Result<Any, Error>) {
    _abstract()
  }
  //
  @inlinable internal func cancel() {
    _abstract()
  }
  //
  @inlinable @discardableResult internal func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    _abstract()
  }
  //
  @inlinable @discardableResult internal func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    _abstract()
  }
  @inlinable internal func add<O: Observer>(observer: O) {
    _abstract()
  }
  @inlinable internal func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    _abstract()
  }
  //
  @inlinable @discardableResult internal func name(_ string: String) -> Self {
    _abstract()
  }
  @inlinable @discardableResult internal func qualityOfService(_ qos: QualityOfService) -> Self {
    _abstract()
  }
  @inlinable @discardableResult internal func queuePriority(_ priority: QueuePriority) -> Self {
    _abstract()
  }

  @inlinable internal init() { }
}

// MARK: -
@usableFromInline
internal final class ProducerTaskBox<Output, Failure: Error>: AnyProducerTaskBox {
  @usableFromInline internal var base: ProducerTask<Output, Failure>
  //
  internal override var operation: AsyncOperation { base.operation }
  //
  @usableFromInline internal var _promise: Future<Any, Error>.Promise!
  @inlinable internal override var promise: Future<Any, Error>.Promise { _promise }
  //
  @inlinable internal override var name: String? { base.name }
  @inlinable internal override var qualityOfService: QualityOfService { base.qualityOfService }
  @inlinable internal override var queuePriority: QueuePriority { base.queuePriority }
  //
  @inlinable internal override var isExecuting: Bool { base.isExecuting }
  @inlinable internal override var isFinished: Bool { base.isFinished }
  @inlinable internal override var isCancelled: Bool { base.isCancelled }
  //
  @inlinable internal override var produced: Result<Any, Error>? { base.produced?.map { $0 as Any }.mapError { $0 as Error } }
  //
  internal override var publisher: AnyPublisher<Any, Error> { base.publisher.map { $0 as Any }.mapError { $0 as Error }.eraseToAnyPublisher() }
  
  internal override func execute() -> AnyPublisher<Any, Error> {
    base.execute().map { $0 as Any }.mapError { $0 as Error }.eraseToAnyPublisher()
  }
  @inlinable internal override func finishing(with produced: Result<Any, Error>) -> AnyPublisher<Void, Never> {
    base.finishing(with: produced.map { $0 as! Output }.mapError { $0 as! Failure })
  }
  @inlinable internal override func finished(with produced: Result<Any, Error>) {
    base.finished(with: produced.map { $0 as! Output }.mapError { $0 as! Failure })
  }
  //
  @inlinable internal override func cancel() {
    base.cancel()
  }
  //
  @inlinable @discardableResult internal override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    base.produce(new: task)
  }
  //
  @inlinable @discardableResult internal override func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    base.add(condition: condition)
  }
  @inlinable internal override func add<O: Observer>(observer: O) {
    base.add(observer: observer)
  }
  @inlinable internal override func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    base.add(dependency: task)
  }
  //
  @inlinable @discardableResult internal override func name(_ string: String) -> Self {
    base.name(string)
    return self
  }
  @inlinable @discardableResult internal override func qualityOfService(_ qos: QualityOfService) -> Self {
    base.qualityOfService(qos)
    return self
  }
  @inlinable @discardableResult internal override func queuePriority(_ priority: QueuePriority) -> Self {
    base.queuePriority(priority)
    return self
  }

  internal init(_base: ProducerTask<Output, Failure>) {
    self.base = _base
    _promise = { _base.promise($0.map { $0 as! Output }.mapError { $0 as! Failure }) }
    super.init()
  }
  @inlinable deinit { }
}

// MARK: -
public final class AnyProducerTask: ProducerTask<Any, Error> {
  @usableFromInline internal let _id: ObjectIdentifier
  @usableFromInline internal let box: AnyProducerTaskBox
  
  internal override var operation: AsyncOperation { box.operation }
  //
  internal override var promise: Future<Any, Error>.Promise { box.promise }
  
  @inlinable public override var id: ObjectIdentifier { _id }
  //
  @inlinable public override var name: String? { box.name }
  @inlinable public override var qualityOfService: QualityOfService { box.qualityOfService }
  @inlinable public override var queuePriority: QueuePriority { box.queuePriority }
  //
  @inlinable public override var isExecuting: Bool { box.isExecuting }
  @inlinable public override var isFinished: Bool  { box.isFinished }
  @inlinable public override var isCancelled: Bool { box.isCancelled }
  //
  @inlinable public override var produced: Produced? { box.produced }
  //
  @inlinable public override var publisher: AnyPublisher<Any, Error> { box.publisher }
  
  @inlinable public override func execute() -> AnyPublisher<Any, Error> {
    box.execute()
  }
  @inlinable public override func finishing(with produced: Produced) -> AnyPublisher<Void, Never> {
    box.finishing(with: produced)
  }
  @inlinable public override func finished(with produced: Produced) {
    box.finished(with: produced)
  }
  //
  @inlinable public override func cancel() {
    box.cancel()
  }
  //
  @inlinable @discardableResult public override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    box.produce(new: task)
  }
  //
  @inlinable @discardableResult public override func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    box.add(condition: condition)
  }
  @inlinable public override func add<O: Observer>(observer: O) {
    box.add(observer: observer)
  }
  @inlinable public override func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    box.add(dependency: task)
  }
  //
  @inlinable @discardableResult public override func name(_ string: String) -> Self {
    box.name(string)
    return self
  }
  @inlinable @discardableResult public override func qualityOfService(_ qos: QualityOfService) -> Self {
    box.qualityOfService(qos)
    return self
  }
  @inlinable @discardableResult public override func queuePriority(_ priority: QueuePriority) -> Self {
    box.queuePriority(priority)
    return self
  }
  
  init<O, F: Error>(_ base: ProducerTask<O, F>) {
    _id = base.id
    box = ProducerTaskBox(_base: base)
    super.init()
  }
}
