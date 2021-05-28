//
//  GatedTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation
import Combine

// MARK: -
public final class GatedTask: NonFailTask {
  // MARK: Private Props
  private let gatedOperation: Operation
  
  // MARK: Public Methods
  public override func execute() -> AnyPublisher<Void, Never> {
    guard !isCancelled else { return Result.Publisher(.success).eraseToAnyPublisher() }
    
    gatedOperation.start()
    
    return gatedOperation
      .publisher(for: \.isFinished, options: [.initial, .new])
      .filter { $0 }
      .flatMap { (_) in Result.Publisher(.success).eraseToAnyPublisher() }
      .eraseToAnyPublisher()
  }
  //
  public override func cancel() {
    gatedOperation.cancel()
    super.cancel()
  }
  
  // MARK: Public Inits
  public init(_ operation: Operation) {
    gatedOperation = operation
    super.init()
  }
}
