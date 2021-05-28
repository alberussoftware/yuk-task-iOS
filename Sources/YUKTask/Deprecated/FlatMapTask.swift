//
//  FlatMapTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/31/20.
//

//import Combine
//
//extension Tasks {
//  public final class FlatMap<UpstreamOutput, UpstreamFailure: Error, Output>: GroupProducerTask<Output, UpstreamFailure> {
//    public let upstream: ProducerTask<UpstreamOutput, UpstreamFailure>
//    public let transform: (UpstreamOutput) -> ProducerTask<Output, UpstreamFailure>
//    
//    init(upstream: ProducerTask<UpstreamOutput, UpstreamFailure>, transform: @escaping (UpstreamOutput) -> ProducerTask<Output, UpstreamFailure>) {
//      self.upstream = upstream
//      self.transform = transform
//      super.init()
//      
//      set(producer: BlockProducerTask<Output, UpstreamFailure> { [weak self] (_) in
//        upstream.publisher
//          .flatMap { (value) -> AnyPublisher<Output, UpstreamFailure> in
//            guard let self = self else { return Empty().eraseToAnyPublisher() }
//            return self.produce(new: transform(value))
//          }
//          .eraseToAnyPublisher()
//      })
//    }
//  }
//}
