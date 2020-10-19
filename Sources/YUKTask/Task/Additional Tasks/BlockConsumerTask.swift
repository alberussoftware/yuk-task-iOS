//
//  BlockConsumerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias BlockConsumerTask<Input, Failure: Error> = BlockConsumerProducerTask<Input, Void, Failure>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailBlockConsumerTask<Input> = BlockConsumerTask<Input, Never>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public typealias NonFailBlockConsumerProducerTask<Input, Output> = BlockConsumerProducerTask<Input, Output, Never>


@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public final class BlockConsumerProducerTask<Input, Output, Failure: Error>:
  ConsumerProducerTask<Input, Output, Failure>
{
  // MARK:
  private let block: Block
  
  // MARK: - API
  // MARK:
  public typealias Block = (BlockConsumerProducerTask, Consumed, @escaping (Produced) -> Void) -> Void
  
  // MARK:
  public override func execute(with consumed: Consumed) {
    block(self, consumed) { (produced) in self.finish(with: produced) }
  }
  
  // MARK:
  public init(
    name: String? = nil,
    qos: QualityOfService = .default,
    priority: Operation.QueuePriority = .normal,
    producing: ProducingTask,
    block: @escaping Block
  ) {
    self.block = block
    super.init(name: name, qos: qos, priority: priority, producing: producing)
  }
}
