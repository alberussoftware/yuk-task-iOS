//
//  EmptyTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/30/20.
//

// MARK: -
public final class EmptyTask: NonFailTask {
  public override func execute(with promise: @escaping Promise) {
    promise(.success)
  }
}
