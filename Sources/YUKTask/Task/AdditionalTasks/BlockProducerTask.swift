//
//  BlockProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

import struct Combine.AnyPublisher

// MARK: -
public final class BlockProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  // MARK: Private Props
  private let block: Block
  
  // MARK: Public Typealiases
  public typealias Block = (_ self: BlockProducerTask) -> AnyPublisher<Output, Failure>
  
  // MARK: Public Methods
  public override func execute() -> AnyPublisher<Output, Failure> {
    block(self)
  }
  
  // MARK: Public Inits
  public init(block: @escaping Block) {
    self.block = block
    super.init()
  }
}

// MARK: -
public typealias NonFailBlockProducerTask<Output> = BlockProducerTask<Output, Never>

// MARK: -
public typealias BlockTask<Failure: Error> = BlockProducerTask<Void, Failure>

// MARK: -
public typealias NonFailBlockTask = BlockTask<Never>
