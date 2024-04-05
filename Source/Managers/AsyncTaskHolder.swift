import Foundation

internal final class AsyncTaskHolder {
    var task: RequestingTask?

    @discardableResult
    init(taskGenerator: (AsyncTaskHolder) -> RequestingTask) {
        let task = taskGenerator(self)
        self.task = task
        task.start()
    }
}
