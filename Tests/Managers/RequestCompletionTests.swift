#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class RequestCompletionTests: XCTestCase {
    func test_complete_queue_completion() {
        let task: FakeSmartTask = .init()

        let subject: FakeRequestCompletion<Int> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        let actual = subject.complete(in: .async(Queue.main), completion: { _ in })
        XCTAssertTrue(task === actual as? FakeSmartTask)
        subject.completion?(1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_completion() {
        let task: FakeSmartTask = .init()

        let subject: FakeRequestCompletion<Int> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        let actual = subject.complete(completion: { _ in })
        XCTAssertTrue(task === actual as? FakeSmartTask)
        subject.completion?(1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: RequestSettings.defaultResponseQueue, Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_oneWay() {
        let detached: FakeDetachedTask = .init()
        detached.stub(.deferredStart).andReturn(detached)

        let task: FakeSmartTask = .init()
        task.stub(.detach).andReturn(detached)

        let subject: FakeRequestCompletion<Int> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        let actual = subject.oneWay()
        XCTAssertTrue(detached === actual as? FakeDetachedTask)
        subject.completion?(1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: RequestSettings.defaultResponseQueue, Argument.closure, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(detached, .deferredStart, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_void() {
        let task: FakeSmartTask = .init()

        let subject: FakeRequestCompletion<Int> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        let actual = subject.complete(completion: {})
        XCTAssertTrue(task === actual as? FakeSmartTask)
        subject.completion?(1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: RequestSettings.defaultResponseQueue, Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_async() async {
        let detached: FakeDetachedTask = .init()
        detached.stub(.deferredStart).andReturn(detached)

        let task: FakeSmartTask = .init()
        task.stub(.detach).andReturn(detached)

        let subject: FakeRequestCompletion<Int> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        async let asyncTask = subject.async()
        Queue.background.async {
            subject.completion?(1)
        }
        let actual = await asyncTask
        XCTAssertEqual(actual, 1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: DelayedQueue.absent, Argument.closure, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(detached, .deferredStart, countSpecifier: .atLeast(1))
    }

    func test_extension_asyncWithThrowing() async throws {
        let detached: FakeDetachedTask = .init()
        detached.stub(.deferredStart).andReturn(detached)

        let task: FakeSmartTask = .init()
        task.stub(.detach).andReturn(detached)

        let subject: FakeRequestCompletion<Result<Int, Error>> = .init()
        subject.stub(.completeWithIn_Completion).andReturn(task)

        async let asyncTask = subject.asyncWithThrowing()
        Queue.background.async {
            subject.completion?(.success(1))
        }
        let actual = try await asyncTask
        XCTAssertEqual(actual, 1)

        XCTAssertHaveReceived(subject, .completeWithIn_Completion, with: DelayedQueue.absent, Argument.closure, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(detached, .deferredStart, countSpecifier: .atLeast(1))
    }
}

@Spryable
private final class FakeRequestCompletion<T>: RequestCompletion, @unchecked Sendable {
    typealias Object = T
    var completion: CompletionClosure?

    func complete(in completionQueue: DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking {
        self.completion = completion
        return spryify(arguments: completionQueue, completion)
    }
}
#endif
