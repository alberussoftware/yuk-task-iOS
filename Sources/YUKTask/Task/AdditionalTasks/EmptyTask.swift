//
//  EmptyTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/30/20.
//

import Combine

// MARK: -
public final class EmptyTask: NonFailTask {
  public override func execute() -> AnyPublisher<Void, Never> {
    Just(()).eraseToAnyPublisher()
  }
}
