import Combine
import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

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
            #if (os(macOS) || os(iOS) || os(visionOS)) && (arch(x86_64) || arch(arm64))
            XCTAssertThrowsAssertion {
                subject?.start()
            }
            #endif

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
