@preconcurrency import Combine
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class SmartTaskTests: XCTestCase {
    func test_cancel_task_once() {
        let subject: UnsafeValue<SmartTasking> = .init()

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject.value = SmartTask(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            subject.value.start()

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
        let subject: UnsafeValue<SmartTasking> = .init()

        let runExp = expectation(description: "should run")
        let cancelExp = expectation(description: "should cancel")
        subject.value = SmartTask(runAction: {
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
        let subject: UnsafeValue<SmartTasking> = .init()
        subject.value = SmartTask(runAction: {
            runExp.fulfill()
        }, cancelAction: {
            cancelExp.fulfill()
        })
        let anySubject: UnsafeValue<AnyCancellable?> = .init()
        anySubject.value = subject.value.map {
            return .init($0)
        }

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
