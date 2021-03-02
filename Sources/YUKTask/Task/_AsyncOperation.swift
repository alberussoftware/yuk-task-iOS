//
//  _AsyncOperation.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/4/21.
//

import class Foundation.Operation
import class YUKLock.RecursiveLock

// MARK: -
internal final class _AsyncOperation: Operation {
  // MARK: Private Props
  private let _lock = RecursiveLock()
  //
  private var _state = State.initialized
  private var state: State {
    get {
      _lock.sync { _state }
    }
    set(newState) {
      // It's important to note that the KVO notifications are NOT called from inside
      // the lock. If they were, the app would deadlock, because in the middle of
      // calling the `didChangeValue(forKey:)` method, the observers try to access
      // properties like `isReady` or `isFinished`. Since those methods also
      // acquire the lock, then we'd be stuck waiting on our own lock. It's the
      // classic definition of deadlock.
      willChangeValue(forKey: "state")
      _lock.sync {
        guard _state != .finished else { return }
        
        precondition(_state.canTransition(to: newState), "Performing invalid state transition")
        
        _state = newState
      }
      didChangeValue(forKey: "state")
    }
  }
  //
  private var _work: Work?
  private var _preparation: Preparation?
  private var _finishing: Finishing?
  private var _finished: Finished?
  //
  private var _hasFinishedAlready = false
  
  // MARK: Internal Typealiases
  internal typealias Work = (_ op: _AsyncOperation, _ completion: @escaping (Completion) -> Void) -> Void
  internal typealias Preparation = (_ op: _AsyncOperation, _ completion: @escaping (Completion) -> Void) -> Void
  internal typealias Finishing = (_ op: _AsyncOperation) -> Void
  internal typealias Finished = (_ op: _AsyncOperation) -> Void
  
  // MARK: Internal Props
  internal override var isReady: Bool {
    _lock.lock()
    defer { _lock.unlock() }
    
    switch _state {
    case .initialized:
      return false
      
    case .pending:
      guard !isCancelled else {
        _state = .ready
        return true
      }
      
      if super.isReady {
        evaluatePreparation()
      }
      
      return false
    
    case .preparation:
      guard !isCancelled else {
        _state = .ready
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
    precondition(_state == .initialized, "You should not call the `cancel()` method before adding to the queue")
    state = .pending
  }
  internal override func start() {
    state = .executing
    main()
  }
  internal override func main() {
    _work?(self) { (_) in self.finish() }
  }
  
  // MARK: Internal Inits
  internal init(_ work: @escaping Work, preparation: Preparation? = nil, finishing: Finishing? = nil, finished: Finished? = nil) {
    _work = work
    _preparation = preparation
    _finishing = finishing
    _finished = finished
    super.init()
  }
}

extension _AsyncOperation {
  private enum State: Comparable {
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
  @objc private static  var keyPathsForValuesAffectings: Set<String> { ["state"] }
  @objc private static func keyPathsForValuesAffectingIsReady() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
  @objc private static func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
  @objc private static func keyPathsForValuesAffectingIsFinished() -> Set<String> {
    _AsyncOperation.keyPathsForValuesAffectings
  }
}

extension _AsyncOperation {
  private func evaluatePreparation() {
    if let preparation = _preparation {
      state = .preparation
      preparation(self) { [weak self] (_) in
        guard self?.isCancelled == false else { return }
        self?.state = .ready
      }
    }
    else {
      state = .ready
    }
  }
  private func finish() {
    guard !_hasFinishedAlready else { return }
    
    _hasFinishedAlready = true
    
    state = .finishing
    _finishing?(self)
    state = .finished
    _finished?(self)
    
    _work = nil
    _preparation = nil
    _finishing = nil
    _finished = nil
  }
}
