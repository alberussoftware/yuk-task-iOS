//
//  ProducerConsumerTasksStressTest.swift
//  YUKTaskTests
//
//  Created by Ruslan Lutfullin on 2/6/21.
//

import XCTest
import Combine
@testable import YUKTask

// MARK: -
final class ProducerConsumerTasksStressTest: XCTestCase {
  func test() {
    var count = 0
    let group = DispatchGroup()
    var cancellables = Set<AnyCancellable>()

    (0..<1_000).forEach { (i) in
      group.enter()
      let task1 = TestTask1().name("\(i)-1")
      let task2 = TestTask2(producing: task1).name("\(i)-2")
      let task3 = TestTask2(producing: task2).name("\(i)-3")
      let task4 = TestTask2(producing: task3).name("\(i)-4")
      let task5 = TestTask2(producing: task4).name("\(i)-5")
      task5.publisher
        .subscribe(on: Self.deliverDispatchQueue)
        .receive(on: Self.deliverDispatchQueue)
        .sink { (value) in
          count += value
          group.leave()
        }
        .store(in: &cancellables)

      Self.taskQueue.add(task1)
      Self.taskQueue.add(task2)
      Self.taskQueue.add(task3)
      Self.taskQueue.add(task4)
      Self.taskQueue.add(task5)
    }

    _ = group.wait(timeout: .distantFuture)
    XCTAssert(count == 5_000)
  }

  static var allTests = [
    ("test", test),
  ]
}

extension ProducerConsumerTasksStressTest {
  private final class TestTask1: NonFailProducerTask<Int> {
    override func execute() -> AnyPublisher<Int, Never> {
      Result.Publisher(.success(1)).eraseToAnyPublisher()
    }
  }
  private final class TestTask2: NonFailConsumerProducerTask<Int, Int> {
    override func execute(with consumed: Consumed?) -> AnyPublisher<Int, Never> {
      Result.Publisher(consumed!.map { $0 + 1 }).eraseToAnyPublisher()
    }
  }
}
