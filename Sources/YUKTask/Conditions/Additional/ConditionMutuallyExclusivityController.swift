//
//  ConditionMutuallyExclusivityController.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/11/20.
//

import Foundation

internal final class _ConditionMutuallyExclusivityController {
  // MARK:
  private let manageQueue =
    DispatchQueue(label: "com.YUKTask.condition-mutually-exclusivity-controller.manage", qos: .userInitiated)
  
  // MARK:
  private var operations = [String: [Operation]]()
  
  // MARK:
  private init() {}
  
  // MARK: -
  // MARK:
  internal func add(_ operation: Operation, forCategories categories: [String]) {
    func addingManage(with operation: Operation, forCategory category: String) {
      var operationsWithThisCategory = operations[category] ?? []
      if let last = operationsWithThisCategory.last {
        operation.addDependency(last)
        
      }
      operationsWithThisCategory.append(operation)
      operations[category] = operationsWithThisCategory
    }
    
    manageQueue.sync { categories.forEach { addingManage(with: operation, forCategory: $0) } }
  }
  
  internal func remove(_ operation: Operation, forCategories categories: [String]) {
    func removeManage(with operation: Operation, forCategory category: String) {
      let matchingOperations = operations[category]
      if var operationsWithThisCategory = matchingOperations,
         let index = operationsWithThisCategory.firstIndex(of: operation)
      {
        operationsWithThisCategory.remove(at: index)
        operations[category] = operationsWithThisCategory
      }
    }
    
    manageQueue.async { categories.forEach { removeManage(with: operation, forCategory: $0) } }
  }
  
  // MARK:
  internal static let shared = _ConditionMutuallyExclusivityController()
}


internal struct _ConditionMutuallyExclusivityObserver {
  // MARK:
  private let categories: [String]
  
  // MARK: -
  // MARK:
  internal init(categories: [String]) {
    self.categories = categories
  }
}

// MARK: -
extension _ConditionMutuallyExclusivityObserver: Observer {
  internal func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
    _ConditionMutuallyExclusivityController.shared.remove(task, forCategories: categories)
  }
}
