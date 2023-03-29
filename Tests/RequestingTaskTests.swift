import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestingTaskTests: XCTestCase {
    func test_cancel_task_once() {
        var subject: RequestingTask?

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject?.start()
            XCTAssertThrowsAssertion {
                subject?.start()
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                subject?.cancel()

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    subject = nil
                }
            }
        }

        wait(for: [runExp, cancelExp], timeout: 0.4)
    }

    func test_cancel_task_on_deinit() {
        var subject: RequestingTask?

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject?.start()

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                subject = nil
            }
        }

        wait(for: [runExp, cancelExp], timeout: 0.3)
    }

    func test_any() {
        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        var subject: RequestingTask? = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })
        var anySubject: AnyCancellable? = subject?.toAny()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject?.deferredStart()
            subject = nil

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                anySubject?.cancel()

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    anySubject = nil
                }
            }
        }

        wait(for: [runExp, cancelExp], timeout: 0.4)
    }
}
