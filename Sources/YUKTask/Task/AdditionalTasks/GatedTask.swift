//
//  GatedTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Combine
import class Foundation.Operation

// MARK: -
public final class GatedTask: NonFailTask {
  // MARK: Private Props
  private let operation: Operation
  
  // MARK: Public Methods
  public override func execute() -> AnyPublisher<Void, Never> {
    guard !isCancelled else { return Just(()).eraseToAnyPublisher() }
    
    operation.start()
    return operation
      .publisher(for: \.isFinished, options: [.initial, .new])
      .filter { $0 }
      .flatMap { (_) in Just(()) }
      .eraseToAnyPublisher()
  }
  //
  public override func cancel() {
    operation.cancel()
    super.cancel()
  }
  
  // MARK: Public Inits
  public init(operation: Operation) {
    self.operation = operation
    super.init()
  }
}
