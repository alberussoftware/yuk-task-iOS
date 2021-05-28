//
//  CatchTask.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/3/20.
//

//import Combine
//
//extension Tasks {
//  public final class Catch<UpstreamOutput, UpstreamFailure: Error, Failure: Error>: GroupProducerTask<UpstreamOutput, Failure> {
//    public let upstream: ProducerTask<UpstreamOutput, UpstreamFailure>
//    public let handler: (UpstreamFailure) -> ProducerTask<UpstreamOutput, Failure>
//
//    init(upstream: ProducerTask<UpstreamOutput, UpstreamFailure>, handler: @escaping (UpstreamFailure) -> ProducerTask<UpstreamOutput, Failure>) {
//      self.upstream = upstream
//      self.handler = handler
//      super.init()
//
//      set(producer: BlockProducerTask<UpstreamOutput, Failure> { [weak self] (_) in
//        upstream.publisher
//          .catch { (error) -> AnyPublisher<UpstreamOutput, Failure> in
//            guard let self = self else { return Empty().eraseToAnyPublisher() }
//            return self.produce(new: handler(error))
//          }
//          .eraseToAnyPublisher()
//      })
//    }
//  }
//}
