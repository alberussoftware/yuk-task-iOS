//
//  Observer.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 1/2/20.
//

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol Observer {
  func taskDidStart<O, F: Error>(_ task: ProducerTask<O, F>)
  func task<O1, F1: Error, O2, F2: Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>)
  func taskDidCancel<O, F: Error>(_ task: ProducerTask<O, F>)
  func taskDidFinish<O, F: Error>(_ task: ProducerTask<O, F>)
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Observer {
  public func taskDidStart<O, F: Error>(_ task: ProducerTask<O, F>) { }
  public func task<O1, F1: Error, O2, F2: Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>) { }
  public func taskDidCancel<O, F: Error>(_ task: ProducerTask<O, F>) { }
  public func taskDidFinish<O, F: Error>(_ task: ProducerTask<O, F>) { }
}

// MARK: -
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
public enum Observers { }
