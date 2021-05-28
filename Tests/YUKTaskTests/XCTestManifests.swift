import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  [testCase(AsyncOperationTests.allTests),
   testCase(ProducerTaskTests.allTests),
   testCase(ConsumerProducerTaskTests.allTests),
   testCase(AnyProducerTaskTests.allTests),
   testCase(GroupProducerTaskTests.allTests),
   testCase(GroupConsumerProducerTaskTests.allTests),
   testCase(ProducerConsumerTasksStressTest.allTests)]
  }
#endif
