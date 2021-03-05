//
//  _TaskQueueObserver.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 3/3/21.
//

// MARK: -
internal struct _TaskQueueObserver: Observer {
  private weak var taskQueue: TaskQueue?
  
  internal func task<O1, F1: Error, O2, F2: Error>(_ task: ProducerTask<O1, F1>, didProduce newTask: ProducerTask<O2, F2>) {
    taskQueue?.add(newTask)
  }
  internal func taskDidFinish<O, F: Error>(_ task: ProducerTask<O, F>) {
    taskQueue?._tasks[task.id] = nil
  }
  
  internal init(taskQueue: TaskQueue) {
    self.taskQueue = taskQueue
  }
}
