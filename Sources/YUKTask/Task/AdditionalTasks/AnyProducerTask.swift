//
//  AnyProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/14/21.
//

import Combine

// MARK: -
@usableFromInline
internal class _AnyProducerTaskBox {
  internal var _operation: _AsyncOperation {
    _abstract()
  }
  //
  @inlinable internal var _promise: Future<Any, Error>.Promise {
    _abstract()
  }
  
  @inlinable internal var name: String? {
    _abstract()
  }
  @inlinable internal var qualityOfService: QualityOfService {
    _abstract()
  }
  @inlinable internal var queuePriority: QueuePriority {
    _abstract()
  }
  //
  @inlinable internal var isExecuting: Bool {
    _abstract()
  }
  @inlinable internal var isFinished: Bool {
    _abstract()
  }
  @inlinable internal var isCancelled: Bool {
    _abstract()
  }
  //
  @inlinable internal var produced: Result<Any, Error>? {
    _abstract()
  }
  //
  @inlinable internal var publisher: AnyPublisher<Any, Error> {
    _abstract()
  }

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
internal final class _ProducerTaskBox<Output, Failure: Error>: _AnyProducerTaskBox {
  @usableFromInline internal var _base: ProducerTask<Output, Failure>
  
  internal override var _operation: _AsyncOperation {
    _base._operation
  }
  //
  @usableFromInline internal var __promise: Future<Any, Error>.Promise!
  @inlinable internal override var _promise: Future<Any, Error>.Promise {
    __promise
  }
  
  //
  @inlinable internal override var name: String? {
    _base.name
  }
  @inlinable internal override var qualityOfService: QualityOfService {
    _base.qualityOfService
  }
  @inlinable internal override var queuePriority: QueuePriority {
    _base.queuePriority
  }
  //
  @inlinable internal override var isExecuting: Bool {
    _base.isExecuting
  }
  @inlinable internal override var isFinished: Bool {
    _base.isFinished
  }
  @inlinable internal override var isCancelled: Bool {
    _base.isCancelled
  }
  //
  @inlinable internal override var produced: Result<Any, Error>? {
    _base.produced?.map { $0 as Any }.mapError { $0 as Error }
  }
  //
  internal override var publisher: AnyPublisher<Any, Error> {
    _base.publisher.map { $0 as Any }.mapError { $0 as Error }.eraseToAnyPublisher()
  }
  
  internal override func execute() -> AnyPublisher<Any, Error> {
    _base.execute().map { $0 as Any }.mapError { $0 as Error }.eraseToAnyPublisher()
  }
  @inlinable internal override func finishing(with produced: Result<Any, Error>) -> AnyPublisher<Void, Never> {
    _base.finishing(with: produced.map { $0 as! Output }.mapError { $0 as! Failure })
  }
  @inlinable internal override func finished(with produced: Result<Any, Error>) {
    _base.finished(with: produced.map { $0 as! Output }.mapError { $0 as! Failure })
  }
  //
  @inlinable internal override func cancel() {
    _base.cancel()
  }
  //
  @inlinable @discardableResult internal override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    _base.produce(new: task)
  }
  //
  @inlinable @discardableResult internal override func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    _base.add(condition: condition)
  }
  @inlinable internal override func add<O: Observer>(observer: O) {
    _base.add(observer: observer)
  }
  @inlinable internal override func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    _base.add(dependency: task)
  }
  //
  @inlinable @discardableResult internal override func name(_ string: String) -> Self {
    _base.name(string)
    return self
  }
  @inlinable @discardableResult internal override func qualityOfService(_ qos: QualityOfService) -> Self {
    _base.qualityOfService(qos)
    return self
  }
  @inlinable @discardableResult internal override func queuePriority(_ priority: QueuePriority) -> Self {
    _base.queuePriority(priority)
    return self
  }

  internal init(_base: ProducerTask<Output, Failure>) {
    self._base = _base
    __promise = { _base._promise($0.map { $0 as! Output }.mapError { $0 as! Failure }) }
    super.init()
  }
  @inlinable deinit { }
}

// MARK: -
public final class AnyProducerTask: ProducerTask<Any, Error> {
  @usableFromInline internal let _id: ObjectIdentifier
  @usableFromInline internal let _box: _AnyProducerTaskBox
  
  internal override var _operation: _AsyncOperation {
    _box._operation
  }
  //
  internal override var _promise: Future<Any, Error>.Promise {
    _box._promise
  }
  
  @inlinable public override var id: ObjectIdentifier {
    _id
  }
  //
  @inlinable public override var name: String? {
    _box.name
  }
  @inlinable public override var qualityOfService: QualityOfService {
    _box.qualityOfService
  }
  @inlinable public override var queuePriority: QueuePriority {
    _box.queuePriority
  }
  //
  @inlinable public override var isExecuting: Bool {
    _box.isExecuting
  }
  @inlinable public override var isFinished: Bool  {
    _box.isFinished
  }
  @inlinable public override var isCancelled: Bool {
    _box.isCancelled
  }
  //
  @inlinable public override var produced: Produced? {
    _box.produced
  }
  //
  @inlinable public override var publisher: AnyPublisher<Any, Error> {
    _box.publisher
  }
  
  @inlinable public override func execute() -> AnyPublisher<Any, Error> {
    _box.execute()
  }
  @inlinable public override func finishing(with produced: Produced) -> AnyPublisher<Void, Never> {
    _box.finishing(with: produced)
  }
  @inlinable public override func finished(with produced: Produced) {
    _box.finished(with: produced)
  }
  //
  @inlinable public override func cancel() {
    _box.cancel()
  }
  //
  @inlinable @discardableResult public override func produce<O, F: Error>(new task: ProducerTask<O, F>) -> AnyPublisher<O, F> {
    _box.produce(new: task)
  }
  //
  @inlinable @discardableResult public override func add<C: Condition>(condition: C) -> AnyPublisher<Void, C.Failure> {
    _box.add(condition: condition)
  }
  @inlinable public override func add<O: Observer>(observer: O) {
    _box.add(observer: observer)
  }
  @inlinable public override func add<O, F: Error>(dependency task: ProducerTask<O, F>) {
    _box.add(dependency: task)
  }
  //
  @inlinable @discardableResult public override func name(_ string: String) -> Self {
    _box.name(string)
    return self
  }
  @inlinable @discardableResult public override func qualityOfService(_ qos: QualityOfService) -> Self {
    _box.qualityOfService(qos)
    return self
  }
  @inlinable @discardableResult public override func queuePriority(_ priority: QueuePriority) -> Self {
    _box.queuePriority(priority)
    return self
  }
  
  init<O, F: Error>(_ base: ProducerTask<O, F>) {
    _id = base.id
    _box = _ProducerTaskBox(_base: base)
    super.init()
  }
}
