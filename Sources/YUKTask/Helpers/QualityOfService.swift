//
//  QualityOfService.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/20/21.
//

import Foundation

// MARK: -
public enum QualityOfService {
  case userInteractive
  case userInitiated
  case utility
  case background
  case `default`
  
  internal var _underline: Foundation.QualityOfService {
    switch self {
    case .userInteractive:
      return .userInteractive
    case .userInitiated:
      return .userInitiated
    case .utility:
      return .utility
    case .background:
      return .background
    case .default:
      return .default
    }
  }
  
  internal init(_ qos: Foundation.QualityOfService) {
    switch qos {
    case .background:
      self = .background
    case .default:
      self = .default
    case .userInitiated:
      self = .userInitiated
    case .userInteractive:
      self = .userInteractive
    case .utility:
      self = .utility
    @unknown default:
      self = .default
    }
  }
}
