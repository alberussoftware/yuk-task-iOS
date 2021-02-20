//
//  GatedTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import class Combine.AnyCancellable
import class Foundation.Operation

// MARK: -
public final class GatedTask: NonFailTask {
  // MARK: Private Props
  private let operation: Operation
  //
  private var cancellable: AnyCancellable?
  
  // MARK: Public Methods
  public override func execute(with promise: @escaping Promise) {
    guard !isCancelled else {
      promise(.success)
      return
    }
    
    operation.start()
    cancellable = operation
      .publisher(for: \.isFinished, options: [.initial, .new])
      .sink {
        guard $0 else { return }
        promise(.success)
      }
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
