import Foundation
import UIKit

import Nimble
import NQueue
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class MultiRequestSpec: QuickSpec {
    fileprivate enum Constant {
        static let numberOfRequests = 6
        static let headerIndexKey = "headerIndexKey"
        static let error: RequestError = .decoding(.nilResponse)
        static let success: ResponseData = .testMake()
        static let failure: ResponseData = .testMake(error: error)
    }

    private typealias Response = Subject.Response

    override func spec() {
        describe("MultiRequestSpec") {
            var subject: Subject!
            var session: FakeSession!

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
                var tasks: [Int: FakeSessionTask]!
                var completionHandlers: [Int: Session.CompletionHandler]!

                beforeEach {
                    completionHandlers = [:]
                    tasks = [:]

                    session.stub(.task).andDo { args in
                        guard let request = args[0] as? URLRequest,
                              let value = request.value(forHTTPHeaderField: Constant.headerIndexKey),
                              let offset = Int(value) else {
                            return nil
                        }

                        if let handler = args[1] as? Session.CompletionHandler {
                            completionHandlers[offset] = handler
                        }
                        return tasks[offset]
                    }

                    for (offset, _) in subject.requests.enumerated() {
                        tasks[offset] = FakeSessionTask()
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
                        expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(100))
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
                        beforeEach {
                            for index in 0..<chunkSize {
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, nil)
                                }
                            }

                            for index in chunkSize..<Constant.numberOfRequests {
                                subject.randomQueue.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                }
                            }
                        }

                        it("should not crash on multithreading") {
                            let expectedResponses: [Response] = Array(repeating: .finished(success: true), count: chunkSize) +
                                Array(repeating: .finished(success: false), count: chunkSize)
                            expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(maxDelayInMilliseconds + 100))
                        }
                    }

                    context("random completion") {
                        beforeEach {
                            for index in 0..<Constant.numberOfRequests {
                                let delay = Int.random(in: 10...maxDelayInMilliseconds)
                                let queue = subject.randomQueue
                                queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                }

                                queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                                    subject.requests[index].cancel()
                                }

                                queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                                    subject.requests[index].restartIfNeeded()
                                }

                                queue.asyncAfter(deadline: .now() + .milliseconds(delay + 100)) {
                                    completionHandlers[index]?(nil, nil, nil)
                                }
                            }
                        }

                        it("should not crash on multithreading") {
                            expect(subject.responses.enumerated().filter { $0.element == .pending }.map(\.offset))
                                .toEventually(beEmpty(),
                                              timeout: .milliseconds(maxDelayInMilliseconds + 200))
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

    let queues: [Queueable] = [Queue.background,
                               Queue.background,
                               Queue.utility,
                               Queue.utility,
                               Queue.userInteractive,
                               Queue.userInteractive,
                               Queue.main]
    var randomQueue: Queueable {
        return queues.randomElement() ?? Queue.utility
    }

    private(set) var requests: [Request] = []
    private(set) var responses: [Response] = []

    init(session: Session,
         numberOfRequests: Int) throws {
        responses = Array(repeating: .pending, count: numberOfRequests)
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
        requests[offset].start { [weak self] data in
            guard let self = self else {
                return
            }

            Queue.main.sync {
                self.responses.remove(at: offset)
                assert(data == Constant.success || data == Constant.failure)
                self.responses.insert(.finished(success: data == Constant.success), at: offset)
            }
        }
    }
}
