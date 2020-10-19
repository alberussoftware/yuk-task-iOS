//
//  EmptyTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/30/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public final class EmptyTask: NonFailTask {
  // MARK: - API
  // MARK:
  public override func execute() {
    finish(with: .success)
  }
}
