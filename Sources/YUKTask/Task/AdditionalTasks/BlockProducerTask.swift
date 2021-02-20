//
//  BlockProducerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/12/20.
//

// MARK: -
public final class BlockProducerTask<Output, Failure: Error>: ProducerTask<Output, Failure> {
  // MARK: Private Props
  private let block: Block
  
  // MARK: Public Typealiases
  public typealias Block = (_ self: BlockProducerTask, _ promise: @escaping Promise) -> Void
  
  // MARK: Public Props
  public override func execute(with promise: @escaping Promise) {
    block(self, promise)
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
