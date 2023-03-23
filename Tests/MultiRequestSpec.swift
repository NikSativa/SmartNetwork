import Foundation
import Nimble
import NQueue
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class MultiRequestSpec: QuickSpec {
    fileprivate enum Constant {
        #if os(macOS)
        static let numberOfRequests = 1000
        #elseif os(iOS)
        static let numberOfRequests = 100
        #endif

        static let headerIndexKey = "headerIndexKey"
        static let error: RequestError = .decoding(.nilResponse)
        static let success: ResponseData = .testMake()
        static let failure: ResponseData = .testMake(error: error)
    }

    private typealias Response = Subject.Response

    override func spec() {
        describe("MultiRequestSpec") {
            var subject: Subject!
            var session: ThreadSafeFakeSession!

            beforeEach {
                session = .init()
                do {
                    subject = try .init(session: session,
                                        numberOfRequests: Constant.numberOfRequests)
                } catch {
                    self.record(.init(type: .thrownError,
                                      compactDescription: error.localizedDescription))
                }
            }

            it("should create multiple requests") {
                expect(subject).toNot(beNil())
                expect(subject.requests.count) == Constant.numberOfRequests
                expect(subject.responses.count) == Constant.numberOfRequests
            }

            context("requesting") {
                var tasks: [Int: ThreadSafeFakeSessionTask]!
                var completionHandlers: CompletionHandlers!

                beforeEach {
                    completionHandlers = .init()
                    tasks = [:]

                    session.stub(.task).andDo { args in
                        guard let request = args[0] as? URLRequest,
                              let value = request.value(forHTTPHeaderField: Constant.headerIndexKey),
                              let offset = Int(value) else {
                            return nil
                        }

                        if let handler = args[1] as? Session.CompletionHandler {
                            completionHandlers[offset] = handler
                        } else {
                            assertionFailure()
                        }
                        return tasks[offset]
                    }

                    for (offset, _) in subject.requests.enumerated() {
                        tasks[offset] = ThreadSafeFakeSessionTask()
                        tasks[offset]?.stub(.resume).andReturn()

                        subject.start(offset: offset)
                    }
                }

                afterEach {
                    for (offset, request) in subject.requests.enumerated() {
                        tasks[offset]?.resetCallsAndStubs()
                        tasks[offset]?.stub(.isRunning).andReturn(false)
                        tasks[offset]?.stub(.cancel).andReturn()
                        request.cancel()
                    }
                }

                it("should create multiple requests") {
                    expect(subject.requests.count) == Constant.numberOfRequests
                    expect(tasks.count) == Constant.numberOfRequests
                    expect(completionHandlers.count) == Constant.numberOfRequests
                }

                context("single request") {
                    let first = 3
                    let second = 5

                    beforeEach {
                        completionHandlers[first]?(nil, nil, nil)
                        completionHandlers[second]?(nil, nil, nil)
                    }

                    it("should mark completion correctly") {
                        var expectedResponses: [Response] = []
                        for i in 0..<Constant.numberOfRequests {
                            expectedResponses.append(first == i || second == i ? .finished(success: true) : .pending)
                        }

                        expect(completionHandlers[first]).toNot(beNil())
                        expect(completionHandlers[second]).toNot(beNil())
                        await expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(100))
                    }
                }

                context("when rendomly completed") {
                    var chunkSize: Int!
                    var maxDelayInMilliseconds: Int!

                    beforeEach {
                        maxDelayInMilliseconds = 100
                        chunkSize = Constant.numberOfRequests / 2

                        for task in tasks.values {
                            task.stub(.isRunning).andReturn(false)
                        }
                    }

                    context("simple completion") {
                        var result: DispatchTimeoutResult!

                        beforeEach {
                            let group = DispatchGroup()

                            for index in 0..<chunkSize {
                                group.enter()
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, nil)
                                    group.leave()
                                }
                            }

                            for index in chunkSize..<Constant.numberOfRequests {
                                group.enter()
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                    group.leave()
                                }
                            }

                            result = group.wait(timeout: .now() + .milliseconds(maxDelayInMilliseconds + min(maxDelayInMilliseconds, 1000)))
                        }

                        it("should not crash on multithreading") {
                            expect(result) == .success

                            let expectedResponses: [Response] = Array(repeating: .finished(success: true), count: chunkSize) +
                                Array(repeating: .finished(success: false), count: chunkSize)
                            let diff: [(Int, Response, Response)] = zip(subject.responses, expectedResponses).enumerated().compactMap { ind, zipped in
                                let (a, b) = (zipped.0, zipped.1)
                                return a != b ? (ind, a, b) : nil
                            }
                            expect(subject.responses).to(equal(expectedResponses), description: "\(diff)")
                            expect(subject.requests.count) == expectedResponses.count
                        }
                    }

                    context("random completion") {
                        var result: DispatchTimeoutResult!

                        beforeEach {
                            let group = DispatchGroup()

                            for index in 0..<Constant.numberOfRequests {
                                let delay = Int.random(in: 10...maxDelayInMilliseconds)
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                }

                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                                    completionHandlers[index]?(nil, nil, nil)
                                }

                                group.enter()
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(maxDelayInMilliseconds + 300)) {
                                    completionHandlers[index]?(nil, nil, nil)
                                    group.leave()
                                }
                            }

                            result = group.wait(timeout: .now() + .milliseconds(maxDelayInMilliseconds + 1000))
                        }

                        it("should not crash on multithreading") {
                            expect(result) == .success
                            expect(subject.responses.enumerated().filter { $0.element == .pending }.map(\.offset)).to(beEmpty())
                        }
                    }
                }
            }
        }
    }
}

private final class Subject {
    private typealias Constant = MultiRequestSpec.Constant

    enum Response: Equatable, SpryEquatable, CustomDebugStringConvertible {
        case pending
        case finished(success: Bool)

        var debugDescription: String {
            switch self {
            case .pending:
                return "pending"
            case .finished(let result):
                return "finished: " + (result ? "success" : "failure")
            }
        }
    }

    let queues: [Queueable] = [
        Queue.background,
        Queue.utility,
        Queue.default,
        Queue.userInitiated,
        Queue.userInteractive
    ]
    var randomQueue: Queueable {
        return queues.randomElement() ?? Queue.utility
    }

    private(set) var requests: [Request] = []
    private(set) var responses: [Response] = []
    private let lock: Mutexing = Mutex.pthread(.recursive)

    init(session: Session,
         numberOfRequests: Int) throws {
        self.responses = Array(repeating: .pending, count: numberOfRequests)
        for index in 0..<numberOfRequests {
            let plugin = Plugins.TokenPlugin(type: .header(.set(Constant.headerIndexKey))) {
                return String(index)
            }

            let queue = queues[index % queues.count]
            let delayedQueue: DelayedQueue = Bool.random() ? .async(queue) : .sync(queue)
            let address = Address.testMake(host: "google_\(index).com")
            let parameters = Parameters.testMake(address: address,
                                                 plugins: [plugin],
                                                 queue: delayedQueue,
                                                 session: session)
            let request: Request = Impl.Request(parameters: parameters,
                                                pluginContext: nil)
            requests.append(request)
        }
    }

    func start(offset: Int) {
        requests[offset].completion = { [weak self] data in
            guard let self else {
                return
            }

            self.lock.sync {
                self.responses.remove(at: offset)
                assert(data == Constant.success || data == Constant.failure)
                self.responses.insert(.finished(success: data == Constant.success), at: offset)
            }
        }
        requests[offset].start()
    }
}

private final class ThreadSafeFakeSession: Session, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case copy = "copy(with:)"
        case task = "task(with:completionHandler:)"
        case finishTasksAndInvalidate = "finishTasksAndInvalidate()"
    }

    private let lock: Mutexing = Mutex.barrier(Queue.custom(label: "Session", attributes: .serial))

    public init() {}

    public func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask {
        return lock.sync {
            return spryify(arguments: request, completionHandler)
        }
    }
}

private final class ThreadSafeFakeSessionTask: SessionTask, Spryable, SpryEquatable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case progress
        case isRunning
        case resume = "resume()"
        case cancel = "cancel()"
        case observe = "observe(_:)"
    }

    private let lock: Mutexing = Mutex.barrier(Queue.custom(label: "SessionTask", attributes: .serial))

    init() {}

    public var progress: Progress {
        return lock.sync {
            return spryify()
        }
    }

    public var isRunning: Bool {
        return lock.sync {
            return spryify(fallbackValue: false)
        }
    }

    public func resume() {
        return lock.sync {
            return spryify(fallbackValue: ())
        }
    }

    public func cancel() {
        return lock.sync {
            return spryify(fallbackValue: ())
        }
    }

    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return lock.sync {
            return spryify(arguments: progressHandler)
        }
    }
}

private final class CompletionHandlers {
    @Atomic
    private var completionHandlers: [Int: Session.CompletionHandler]

    init() {
        let mutex: Mutexing = Mutex.barrier(Queue.custom(label: "CompletionHandlers",
                                                         qos: .background,
                                                         attributes: .serial))
        _completionHandlers = .init(wrappedValue: [:],
                                    mutex: mutex,
                                    read: .sync,
                                    write: .sync)
    }

    var count: Int {
        return completionHandlers.count
    }

    subscript(_ key: Int) -> Session.CompletionHandler? {
        get {
            return completionHandlers[key]
        }
        set {
            completionHandlers[key] = newValue
        }
    }
}
