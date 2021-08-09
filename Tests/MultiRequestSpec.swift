import Foundation
import UIKit

import Quick
import Nimble
import NSpry
import NCallback
import NQueue

@testable import NRequest
@testable import NRequestTestHelpers

final class MultiRequestSpec: QuickSpec {
    fileprivate enum Constant {
        static let numberOfRequests = 1000
        static let error: RequestError = .decoding(.nilResponse)
        static let error2: RequestError = .decoding(.brokenResponse)
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
                } catch let error {
                    self.record(.init(type: .thrownError,
                                      compactDescription: error.localizedDescription))
                }
            }

            it("should create multiple requests") {
                expect(subject).toNot(beNil())
                expect(subject.requests.count) == Constant.numberOfRequests
                expect(subject.responses.count) == Constant.numberOfRequests
                expect(subject.sdkRequests.count) == Constant.numberOfRequests
            }

            context("requesting") {
                var tasks: [Int: FakeSessionTask]!
                var completionHandlers: [Int: Session.CompletionHandler]!

                beforeEach {
                    completionHandlers = [:]
                    tasks = [:]

                    for (offset, request) in subject.requests.enumerated() {
                        tasks[offset] = FakeSessionTask()
                        tasks[offset]?.stub(.resume).andReturn()

                        session.stub(.task).with(subject.sdkRequests[offset], Argument.anything).andDo { args in
                            if let handler = args[1] as? Session.CompletionHandler {
                                completionHandlers[offset] = handler
                            }
                            return tasks[offset]
                        }

                        request.start()
                    }
                }

                afterEach {
                    for (offset, request) in subject.requests.enumerated() {
                        tasks[offset]?.resetCallsAndStubs()
                        tasks[offset]?.stub(.isRunning).andReturn(false)
                        tasks[offset]?.stub(.cancel).andReturn()
                        request.stop()
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
                        tasks[first]?.stub(.isRunning).andReturn(false)

                        tasks[second]?.stub(.isRunning).andReturn(true)
                        tasks[second]?.stub(.cancel).andReturn()

                        completionHandlers[first]?(nil, nil, nil)
                        completionHandlers[second]?(nil, nil, nil)
                    }

                    it("should mark completion correctly") {
                        var expectedResponses: [Response] = []
                        for i in 0..<Constant.numberOfRequests {
                            expectedResponses.append(first == i || second == i ? .normal(.success(.init())) : .pending)
                        }

                        expect(completionHandlers[first]).toNot(beNil())
                        expect(completionHandlers[second]).toNot(beNil())
                        expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(100))
                    }

                    it("should resume all tasks") {
                        expect(tasks[first]).to(haveReceived(.isRunning))

                        expect(tasks[second]).to(haveReceived(.isRunning))
                        expect(tasks[second]).to(haveReceived(.cancel))
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
                                Queue.background.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, nil)
                                }
                            }

                            for index in chunkSize..<Constant.numberOfRequests {
                                Queue.userInitiated.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                }
                            }
                        }

                        it("should not crash on multithreading") {
                            let expectedResponses: [Response] = Array(repeating: .normal(.success(.init())), count: chunkSize) +
                            Array(repeating: .normal(.failure(Constant.error)), count: chunkSize)
                            expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(maxDelayInMilliseconds + 100))
                        }
                    }

                    context("special completion") {
                        beforeEach {
                            for index in 0..<chunkSize {
                                subject.makeSpecial(at: index)

                                Queue.background.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, Constant.error)
                                }
                            }

                            for index in chunkSize..<Constant.numberOfRequests {
                                subject.makeSpecial(at: index)

                                Queue.userInitiated.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 10...maxDelayInMilliseconds))) {
                                    completionHandlers[index]?(nil, nil, Constant.error2)
                                }
                            }
                        }

                        it("should not crash on multithreading") {
                            let expectedResponses: [Response] = Array(repeating: .special(Constant.error), count: chunkSize) +
                            Array(repeating: .normal(.failure(Constant.error2)), count: chunkSize)
                            expect(subject.responses).toEventually(equal(expectedResponses), timeout: .milliseconds(maxDelayInMilliseconds + 100))
                        }
                    }
                }
            }
        }
    }
}

private final class Subject {
    typealias MyRequest = Impl.Request<IgnorableContent<RequestError>, RequestError>

    enum Response: Equatable, SpryEquatable, CustomDebugStringConvertible {
        case pending
        case normal(Result<Ignorable, RequestError>)
        case special(RequestError?)

        var debugDescription: String {
            switch self {
            case .pending:
                return "pending"
            case .normal(let result):
                switch result {
                case .success:
                    return "normal - success"
                case .failure:
                    return "normal - failure"
                }
            case .special(let error):
                return "special - \(error?.localizedDescription ?? "nil")"
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
    private(set) var requests: [MyRequest] = []
    private(set) var responses: [Response] = []
    private(set) var sdkRequests: [Int: URLRequest] = [:]

    init(session: Session,
         numberOfRequests: Int) throws {
        responses = Array(repeating: .pending, count: numberOfRequests)
        for index in 0..<numberOfRequests {
            let queue = queues[index % queues.count]
            let delayedQueue: DelayedQueue = Bool.random() ? .async(queue) : .sync(queue)
            let address = Address.testMake(host: "google_\(index).com")
            let parameters = Parameters.testMake(address: address,
                                                 queue: delayedQueue,
                                                 session: session)

            let request: MyRequest = try MyRequest(parameters: parameters)
            sdkRequests[index] = request.info.request.original

            request.onComplete { [weak self] result in
                guard let self = self else {
                    return
                }

                Queue.main.sync {
                    self.responses.remove(at: index)
                    self.responses.insert(.normal(result), at: index)
                }
            }

            requests.append(request)
        }
    }

    func makeSpecial(at index: Int) {
        requests[index].onSpecialComplete { [weak self] _, _, _, error in
            guard let self = self else {
                return .ignore
            }

            Queue.main.sync {
                self.responses.remove(at: index)
                self.responses.insert(.special(error.map({ .wrap($0) })), at: index)
            }

            guard let error = error as? RequestError else {
                return .ignore
            }

            if error == MultiRequestSpec.Constant.error2 {
                return .passOver
            }

            return .ignore
        }
    }
}
