@preconcurrency import Combine
import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class RequestingTaskTests: XCTestCase {
    func test_cancel_task_once() {
        let subject: SendableResult<RequestingTask> = .init()

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject.value = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject.value.start()
            #if (os(macOS) || os(iOS) || supportsVisionOS) && (arch(x86_64) || arch(arm64))
            XCTAssertThrowsAssertion {
                subject.value.start()
            }
            #endif

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                subject.value.cancel()

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    subject.value = nil
                }
            }
        }

        wait(for: [runExp, cancelExp], timeout: 3)
    }

    func test_cancel_task_on_deinit() {
        let subject: SendableResult<RequestingTask> = .init()

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject.value = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject.value.start()

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                subject.value = nil
            }
        }

        wait(for: [runExp, cancelExp], timeout: 3)
    }

    func test_any() {
        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        let subject: SendableResult<RequestingTask> = .init()
        subject.value = .init(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })
        let anySubject: SendableResult<AnyCancellable?> = .init()
        anySubject.value = subject.value?.toAny()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject.value?.deferredStart()
            subject.value = nil

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                anySubject.value?.cancel()

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    anySubject.value = nil
                }
            }
        }

        wait(for: [runExp, cancelExp], timeout: 3)
    }
}
