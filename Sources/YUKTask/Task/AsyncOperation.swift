//
//  _AsyncOperation.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/4/21.
//

import Foundation
import Combine
import YUKLock

// MARK: -
internal final class AsyncOperation: Operation {
  // MARK: Private Props
  private let stateLock = RecursiveLock()
  private var _state = State.initialized
  //
  private var preparation: Preparation?
  private var work: Work?
  private var finishingHandler: FinishingHandler?
  private var finishedHandler: FinishedHandler?
  //
  private var hasFinishedAlready = false
  
  // MARK: Internal Typealiases
  internal typealias Preparation = (_ op: AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias Work = (_ op: AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias FinishingHandler = (_ op: AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias FinishedHandler = (_ op: AsyncOperation) -> Void
  
  // MARK: Internal Props
  internal private(set) var state: State {
    get {
      stateLock.sync { _state }
    }
    set(newState) {
      // It's important to note that the KVO notifications are NOT called from inside
      // the lock. If they were, the app would deadlock, because in the middle of
      // calling the `didChangeValue(forKey:)` method, the observers try to access
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
  //
  internal override var isReady: Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    
    switch state {
    case .initialized:
      return false
      
    case .pending:
      guard !isCancelled else {
        state = .ready
        return true
      }
      
      if super.isReady {
        evaluatePreparation()
          .subscribe(Subscribers.Sink { (_) in
            if self.isCancelled == false { self.state = .ready }
          })
      }
      
      return false
      
    case .preparation:
      guard !isCancelled else {
        state = .ready
        return true
      }
      
      return false
      
    case .ready:
      return super.isReady || isCancelled
      
    default:
      return false
    }
  }
  internal override var isExecuting: Bool { state == .executing }
  internal override var isFinished: Bool { state == .finished }
  internal override var isAsynchronous: Bool { true }
  
  // MARK: Internal Methods
  internal func willEnqueue() {
    precondition(state == .initialized, "You should not call the `cancel()` method before adding to the queue")
    state = .pending
  }
  internal override func start() {
    state = .executing
    main()
  }
  internal override func main() {
    work?(self)
      .flatMap { [weak self] (_) -> AnyPublisher<Void, Never> in
        guard let self = self else { return Result.Publisher(.success).eraseToAnyPublisher() }
        
        guard !self.hasFinishedAlready else { return Result.Publisher(.success).eraseToAnyPublisher() }
        
        self.hasFinishedAlready = true
        
        self.state = .finishing
        
        if let finishing = self.finishingHandler {
          return finishing(self)
        }
        else {
          return Result.Publisher(.success).eraseToAnyPublisher()
        }
      }
      .eraseToAnyPublisher()
      .subscribe(Subscribers.Sink { (_) in
        self.state = .finished
        
        self.preparation = nil
        self.work = nil
        self.finishingHandler = nil
        
        self.finishedHandler?(self)
        self.finishedHandler = nil
      })
  }
  
  // MARK: Internal Inits
  internal init(preparation: Preparation? = nil, work: @escaping Work, onFinishing: FinishingHandler? = nil, onFinished: FinishedHandler? = nil) {
    self.preparation = preparation
    self.work = work
    finishingHandler = onFinishing
    finishedHandler = onFinished
    super.init()
  }
}

extension AsyncOperation {
  internal enum State: Comparable {
    case initialized
    case pending
    case preparation
    case ready
    case executing
    case finishing
    case finished
    
    func canTransition(to newState: State) -> Bool {
      switch (self, newState) {
      case (.initialized, .pending),
           (.pending, .ready),
           (.pending, .preparation),
           (.preparation, .ready),
           (.ready, .executing),
           (.executing, .finishing),
           (.finishing, .finished):
        return true
      default:
        return false
      }
    }
  }
}

extension AsyncOperation {
  private enum CancellableKey {
    case work
    case preparation
  }
}

extension AsyncOperation {
  @objc private static  var keyPathsForValuesAffectings: Set<String> { ["state"] }
  @objc private static func keyPathsForValuesAffectingIsReady() -> Set<String> {
    AsyncOperation.keyPathsForValuesAffectings
  }
  @objc private static func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
    AsyncOperation.keyPathsForValuesAffectings
  }
  @objc private static func keyPathsForValuesAffectingIsFinished() -> Set<String> {
    AsyncOperation.keyPathsForValuesAffectings
  }
}

extension AsyncOperation {
  private func evaluatePreparation() -> AnyPublisher<Void, Never> {
    if let preparation = preparation {
      state = .preparation
      return preparation(self)
    }
    else {
      return Result.Publisher(.success).eraseToAnyPublisher()
    }
  }
}
