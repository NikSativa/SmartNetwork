import Combine
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class RequestMultithreadTests: XCTestCase {
    private let maxRequests = 500
    private let timoutInSeconds: TimeInterval = 5
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1

    private let host1 = "example1.com"
    private let address1: Address = .testMake(string: "http://example1.com/signin")

    private let testObj = TestInfo(id: 1)

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var exps: [XCTestExpectation] = []
    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var result: [TestInfo?] = []

    private let subject = SmartRequestManager.create()
    private var observers: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(host1),
                                  body: .encode(TestInfo(id: 1)),
                                  delayInSeconds: stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
        result = []
    }

    func test_threads_closure() {
        threads { [self] exp, comp in
            subject.request(address: address1).decode(TestInfo.self).complete { [exp] obj in
                comp(try! obj.get())
                exp.fulfill()
            }.storing(in: &observers).start()
        }
    }

    func test_threads_async() {
        threads { [self] exp, comp in
            Task {
                let obj = await subject.request(address: address1).decode(TestInfo.self).async()
                comp(try! obj.get())
                exp.fulfill()
            }
        }
    }

    func test_threads() {
        threads { [self] exp, comp in
            if Bool.random() {
                subject.request(address: address1).decode(TestInfo.self).complete { [exp] obj in
                    comp(try! obj.get())
                    exp.fulfill()
                }.detach().deferredStart()
            } else {
                Task {
                    let obj = await subject.request(address: address1).decode(TestInfo.self).async()
                    comp(try! obj.get())
                    exp.fulfill()
                }
            }
        }
    }

    #if swift(>=6.0)
    private func threads(_ processor: @escaping @Sendable (XCTestExpectation, @escaping @Sendable (TestInfo) -> Void) -> Void,
                         file: StaticString = #filePath,
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

        XCTAssertEqual(group.wait(timeout: .now() + 2), .success, file: file, line: line)
        wait(for: exps, timeout: timoutInSeconds)

        XCTAssertEqual(result, .init(repeating: testObj, count: result.count), file: file, line: line)
        XCTAssertEqual(result.count, maxRequests, "results", file: file, line: line)
        XCTAssertEqual(exps.count, maxRequests, "exps", file: file, line: line)
    }
    #else
    private func threads(_ processor: @escaping (XCTestExpectation, @escaping (TestInfo) -> Void) -> Void,
                         file: StaticString = #filePath,
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

        XCTAssertEqual(group.wait(timeout: .now() + 2), .success, file: file, line: line)
        wait(for: exps, timeout: timoutInSeconds)

        XCTAssertEqual(result, .init(repeating: testObj, count: result.count), file: file, line: line)
        XCTAssertEqual(result.count, maxRequests, "results", file: file, line: line)
        XCTAssertEqual(exps.count, maxRequests, "exps", file: file, line: line)
    }
    #endif
}

#if swift(>=6.0)
extension RequestMultithreadTests: @unchecked Sendable {}
#endif
