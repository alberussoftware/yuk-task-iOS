//
//  ConditionMutuallyExclusivityController.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/11/20.
//


// MARK: -
//internal final class _ConditionMutuallyExclusivityController {
//  private let manageQueue = DispatchQueue(label: "com.YUKTask.condition-mutually-exclusivity-controller.manage", qos: .userInitiated)
//  private var operations = [String: [Operation]]()
//
//  internal func add(_ operation: Operation, forCategories categories: [String]) {
//    func addingManage(with operation: Operation, forCategory category: String) {
//      var operationsWithThisCategory = operations[category] ?? []
//      if let last = operationsWithThisCategory.last {
//        operation.addDependency(last)
//
//      }
//      operationsWithThisCategory.append(operation)
//      operations[category] = operationsWithThisCategory
//    }
//
//    manageQueue.sync { categories.forEach { addingManage(with: operation, forCategory: $0) } }
//  }
//  internal func remove(_ operation: Operation, forCategories categories: [String]) {
//    func removeManage(with operation: Operation, forCategory category: String) {
//      let matchingOperations = operations[category]
//      if var operationsWithThisCategory = matchingOperations,
//         let index = operationsWithThisCategory.firstIndex(of: operation)
//      {
//        operationsWithThisCategory.remove(at: index)
//        operations[category] = operationsWithThisCategory
//      }
//    }
//
//    manageQueue.async { categories.forEach { removeManage(with: operation, forCategory: $0) } }
//  }
//
//  internal static let shared = _ConditionMutuallyExclusivityController()
//
//  private init() { }
//}

// MARK: -
//internal struct _ConditionMutuallyExclusivityObserver: Observer {
//  let categories: [String]
//  
//  func taskDidFinish<T: ProducerTaskProtocol>(_ task: T) {
//    _ConditionMutuallyExclusivityController.shared.remove(task, forCategories: categories)
//  }
//  
//  init(categories: [String]) {
//    self.categories = categories
//  }
//}
