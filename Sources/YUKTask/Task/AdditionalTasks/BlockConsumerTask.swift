//
//  BlockConsumerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import Combine

// MARK: -
public final class BlockConsumerProducerTask<Input, Output, Failure: Error>: ConsumerProducerTask<Input, Output, Failure> {
  // MARK: Private Props
  private let block: Block
  
  // MARK: Private Typealias
  public typealias Block = (_ self: BlockConsumerProducerTask, _ consumed: Consumed?) -> AnyPublisher<Output, Failure>
  
  // MARK: Public Methods
  public override func execute(with consumed: Consumed?) -> AnyPublisher<Output, Failure> {
    block(self, consumed)
  }
  
  // MARK: Public Inits
  public init(producing: Producing, block: @escaping Block) {
    self.block = block
    super.init(producing: producing)
  }
}

// MARK: -
public typealias NonFailBlockConsumerProducerTask<Input, Output> = BlockConsumerProducerTask<Input, Output, Never>

// MARK: -
public typealias NonFailBlockConsumerTask<Input> = BlockConsumerTask<Input, Never>

// MARK: -
public typealias BlockConsumerTask<Input, Failure: Error> = BlockConsumerProducerTask<Input, Void, Failure>
