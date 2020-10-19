import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  [
    testCase(AdditionalTasksTests.allTests),
    testCase(TasksNamespaceTests.allTests),
  ]
}
#endif
