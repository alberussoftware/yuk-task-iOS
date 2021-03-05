//
//  _AsyncOperation.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/4/21.
//

import class Foundation.Operation
import YUKLock
import Combine

// MARK: -
internal final class _AsyncOperation: Operation {
  // MARK: Private Props
  @UnfairLocked
  private var _cancellables = [CancellableKey: AnyCancellable]()
  //
  private let _stateLock = RecursiveLock()
  private var _state = State.initialized
  //
  private var _work: Work?
  private var _preparation: Preparation?
  private var _finishing: Finishing?
  private var _finished: Finished?
  //
  private var _hasFinishedAlready = false
  
  // MARK: Internal Typealiases
  internal typealias Work = (_ op: _AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias Preparation = (_ op: _AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias Finishing = (_ op: _AsyncOperation) -> AnyPublisher<Void, Never>
  internal typealias Finished = (_ op: _AsyncOperation) -> Void
  
  // MARK: Internal Props
  internal private(set) var state: State {
    get { _stateLock.sync { _state } }
    set(newState) {
      // It's important to note that the KVO notifications are NOT called from inside
      // the lock. If they were, the app would deadlock, because in the middle of
      // calling the `didChangeValue(forKey:)` method, the observers try to access
      // properties like `isReady` or `isFinished`. Since those methods also
      // acquire the lock, then we'd be stuck waiting on our own lock. It's the
      // classic definition of deadlock.
      willChangeValue(forKey: "state")
      _stateLock.sync {
        guard _state != .finished else { return }
        precondition(_state.canTransition(to: newState), "Performing invalid state transition")
        _state = newState
      }
      didChangeValue(forKey: "state")
    }
  }
  //
  internal override var isReady: Bool {
    _stateLock.lock()
    defer { _stateLock.unlock() }
    
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
          .sink { [weak self] in
            if self?.isCancelled == false { self?.state = .ready }
            self?.$_cancellables.read { $0[.preparation]?.cancel() }
          }
          .store(in: $_cancellables, at: .preparation)
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
    _work?(self)
      .flatMap { [weak self] (_) -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }
        guard !self._hasFinishedAlready else { return Empty().eraseToAnyPublisher() }
        self._hasFinishedAlready = true
        
        self.state = .finishing
        if let finishing = self._finishing {
          return finishing(self)
        }
        else {
          return Just(()).eraseToAnyPublisher()
        }
      }
      .sink { [weak self] in
        guard let self = self else { return }
        self.state = .finished
        self._work = nil
        self._preparation = nil
        self._finishing = nil
        self._finished?(self)
        self._finished = nil
        self.$_cancellables.read { $0[.work]?.cancel() }
      }
      .store(in: $_cancellables, at: .work)
  }
  
  // MARK: Internal Inits
  internal init(preparation: Preparation? = nil, work: @escaping Work, finishing: Finishing? = nil, finished: Finished? = nil) {
    _preparation = preparation
    _work = work
    _finishing = finishing
    _finished = finished
    super.init()
  }
}

extension _AsyncOperation {
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

extension _AsyncOperation {
  private enum CancellableKey {
    case work
    case preparation
  }
}

extension _AsyncOperation {
  @objc
  private static  var keyPathsForValuesAffectings: Set<String> { ["state"] }
  @objc
  private static func keyPathsForValuesAffectingIsReady() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
  @objc
  private static func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
  @objc
  private static func keyPathsForValuesAffectingIsFinished() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
}

extension _AsyncOperation {
  private func evaluatePreparation() -> AnyPublisher<Void, Never> {
    if let preparation = self._preparation {
      state = .preparation
      return preparation(self)
    }
    else {
      return Just(()).eraseToAnyPublisher()
    }
  }
}
