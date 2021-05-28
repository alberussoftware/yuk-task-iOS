//
//  QueuePriority.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/20/21.
//

import Foundation

// MARK: -
public enum QueuePriority {
  case veryLow
  case low
  case normal
  case high
  case veryHigh
  
  internal var _underline: Operation.QueuePriority {
    switch self {
    case .veryLow:
      return .veryLow
    case .low:
      return .low
    case .normal:
      return .normal
    case .high:
      return .high
    case .veryHigh:
      return .veryHigh
    }
  }
  
  internal init(_ priority: Operation.QueuePriority) {
    switch priority {
    case .veryLow:
      self = .veryLow
    case .low:
      self = .low
    case .normal:
      self = .normal
    case .high:
      self = .high
    case .veryHigh:
      self = .veryHigh
    @unknown default:
      self = .normal
    }
  }
}
