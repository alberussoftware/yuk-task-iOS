//
//  ConsumerTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/4/20.
//

import Combine

// MARK: -
open class ConsumerProducerTask<Input, Output, Failure: Error>: ProducerTask<Output, Failure> {
  // MARK: Public Typealiases
  public typealias Producing = ProducerTask<Input, Failure>
  public typealias Consumed = Producing.Produced
  
  // MARK: Public Props
  public final let producing: Producing
  //
  public final var consumed: Consumed? { producing.produced }
  
  // MARK: Public Methods
  public final override func execute() -> AnyPublisher<Output, Failure> {
    execute(with: consumed)
  }
  open func execute(with consumed: Consumed?) -> AnyPublisher<Output, Failure> {
    _abstract()
  }
  
  // MARK: Public Inits
  public init(producing: Producing) {
    self.producing = producing
    super.init()
    add(dependency: producing)
  }
}

// MARK: -
public typealias NonFailConsumerProducerTask<Input, Output> = ConsumerProducerTask<Input, Output, Never>

// MARK: -
public typealias ConsumerTask<Input, Failure: Error> = ConsumerProducerTask<Input, Void, Failure>

// MARK: -
public typealias NonFailConsumerTask<Input> = ConsumerTask<Input, Never>
