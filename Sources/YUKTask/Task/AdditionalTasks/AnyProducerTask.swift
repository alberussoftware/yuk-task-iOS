//
//  AnyProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/14/21.
//

import class Combine.Future
import struct Combine.Published
import class Combine.AnyCancellable

// MARK: -
@_fixed_layout
@usableFromInline
internal class _AnyProducerTaskBox {
  internal var _operation: _AsyncOperation {
    _abstract()
  }
  //
  internal var _promise: Combine.Future<Any, Error>.Promise {
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
  @inlinable internal var publisher: Combine.Future<Any, Error> {
    _abstract()
  }

  @inlinable internal func execute(with promise: @escaping Combine.Future<Any, Error>.Promise) {
    _abstract()
  }
  @inlinable internal func finishing(with produced: Result<Any, Error>) {
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
  @inlinable internal func produce<O, F: Error>(new task: ProducerTask<O, F>) {
    _abstract()
  }
  //
  @inlinable @discardableResult internal func add<C: Condition>(condition: C) -> C.Future {
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
@_fixed_layout
@usableFromInline
internal final class _ProducerTaskBox<Output, Failure: Error>: _AnyProducerTaskBox {
  private var __publisher: Combine.Future<Any, Error>!
  private var __promise: Future<Any, Error>.Promise!
  private var __cancellable: AnyCancellable?
  
  @usableFromInline internal var _base: ProducerTask<Output, Failure>
  
  internal override var _operation: _AsyncOperation {
    _base._operation
  }
  //
  internal override var _promise: Future<Any, Error>.Promise {
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
  internal override var publisher: Combine.Future<Any, Error> {
    __publisher
  }
  
  internal override func execute(with promise: @escaping Combine.Future<Any, Error>.Promise) {
    _base.execute(with: _base._promise)
  }
  @inlinable internal override func finishing(with produced: Result<Any, Error>) {
    _base.finishing(with: _base.produced!.map { $0 as Output }.mapError { $0 as Failure })
  }
  @inlinable internal override func finished(with produced: Result<Any, Error>) {
    _base.finished(with: _base.produced!.map { $0 as Output }.mapError { $0 as Failure })
  }
  //
  @inlinable internal override func cancel() {
    _base.cancel()
  }
  //
  @inlinable internal override func produce<O, F: Error>(new task: ProducerTask<O, F>) {
    _base.produce(new: task)
  }
  //
  @inlinable @discardableResult internal override func add<C: Condition>(condition: C) -> C.Future {
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
    super.init()
    
    __publisher = .init { [weak self] (promise) in self?.__promise = promise }
    
    __cancellable = _base
      .publisher
      .sink { [weak self] in
        switch $0 {
        case let .failure(error):
          self?.__promise(.failure(error))
        default:
          break
        }
      } receiveValue: { [weak self] in
        self?.__promise(.success($0))
      }
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
  internal override var _promise: Promise {
    _box._promise
  }
  
  public override var id: ObjectIdentifier {
    _id
  }
  //
  public override var name: String? {
    _box.name
  }
  public override var qualityOfService: QualityOfService {
    _box.qualityOfService
  }
  public override var queuePriority: QueuePriority {
    _box.queuePriority
  }
  //
  public override var isExecuting: Bool {
    _box.isExecuting
  }
  public override var isFinished: Bool  {
    _box.isFinished
  }
  public override var isCancelled: Bool {
    _box.isCancelled
  }
  //
  @inlinable public override var produced: Produced? {
    _box.produced
  }
  //
  @inlinable public override var publisher: Future {
    _box.publisher
  }
  
  @inlinable public override func execute(with promise: @escaping Promise) {
    _box.execute(with: promise)
  }
  @inlinable public override func finishing(with produced: Produced) {
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
  @inlinable public override func produce<O, F: Error>(new task: ProducerTask<O, F>) {
    _box.produce(new: task)
  }
  //
  @inlinable @discardableResult public override func add<C: Condition>(condition: C) -> C.Future {
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
