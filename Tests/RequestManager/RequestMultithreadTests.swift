import Combine
import Foundation
import NQueue
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestMultithreadTests: XCTestCase {
    private let maxRequests = 200
    private let timoutInSeconds: TimeInterval = 1
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1

    private let host1 = "example1.com"
    private let address1: Address = .testMake(string: "http://example1.com/signin")

    private let testObj = TestInfo(id: 1)

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var exps: [XCTestExpectation] = []
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var result: [TestInfo?] = []

    private let subject = RequestManager.create()
    private var observers: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(host1),
                                  body: .encodable(TestInfo(id: 1)),
                                  delayInSeconds: stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
        result = []
    }

    func test_threads_closure() {
        threads { [self] exp, comp in
            subject.requestDecodable(TestInfo.self,
                                     address: address1) { [exp] obj in
                comp(try! obj.get())
                exp.fulfill()
            }.deferredStart().store(in: &observers)
        }
    }

    func test_threads_async() {
        threads { [self] exp, comp in
            Task {
                let obj = await subject.requestDecodable(TestInfo.self,
                                                         address: address1)
                comp(try! obj.get())
                exp.fulfill()
            }
        }
    }

    func test_threads() {
        threads { [self] exp, comp in
            if Bool.random() {
                subject.requestDecodable(TestInfo.self,
                                         address: address1) { [exp] obj in
                    comp(try! obj.get())
                    exp.fulfill()
                }.deferredStart().store(in: &observers)
            } else {
                Task {
                    let obj = await subject.requestDecodable(TestInfo.self,
                                                             address: address1)
                    comp(try! obj.get())
                    exp.fulfill()
                }
            }
        }
    }

    private func threads(_ processor: @escaping (XCTestExpectation, @escaping (TestInfo) -> Void) -> Void,
                         file: StaticString = #file,
                         line: UInt = #line) {
        let group = DispatchGroup()
        for i in 0..<maxRequests {
            let randDelay: Double = .init((0...20).randomElement()!) / 100.0
            group.enter()
            Queue.default.asyncAfter(deadline: .now() + randDelay) { [self] in
                $exps.mutate { exps in
                    let exp = expectation(description: "request \(i)")
                    exps.append(exp)
                    group.leave()

                    processor(exp) { [self] new in
                        $result.mutate { results in
                            results.append(new)
                        }
                    }
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 0.5), .success, file: file, line: line)
        wait(for: exps, timeout: timoutInSeconds)

        XCTAssertEqual(result, .init(repeating: testObj, count: result.count), file: file, line: line)
        XCTAssertEqual(result.count, maxRequests, "results", file: file, line: line)
        XCTAssertEqual(exps.count, maxRequests, "exps", file: file, line: line)
    }
}
