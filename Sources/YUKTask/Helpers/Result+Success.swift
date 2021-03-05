//
//  Result+Success.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/20/21.
//

// MARK: -
extension Result where Success == Void {
  public static var success: Self { .success(()) }
}
