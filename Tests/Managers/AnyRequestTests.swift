#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SpryKit
import Threading
import XCTest
@testable import SmartNetwork

@MainActor
final class AnyRequestTests: XCTestCase {
    func test_subject() {
        let address: Address = .testMake()
        let parameters: Parameters = .testMake()
        let userInfo: UserInfo = .testMake()
        let manager: FakeRequestManager = .init()
        let task: FakeSmartTask = .init()
        let detachedTask: FakeDetachedTask = .init()
        manager.stub(.requestWithAddress_Parameters_Userinfo_Completionqueue_Completion).andReturn(task)
        manager.stub(.requestWithAddress_Parameters_Userinfo).andReturn(SmartResponse.testMake())

        let subject = AnyRequest(pure: manager, address: address, parameters: parameters, userInfo: userInfo)

        task.stub(.detach).andReturn(detachedTask)
        detachedTask.stub(.deferredStart).andReturn(detachedTask)
        subject.oneWay()
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo_Completionqueue_Completion, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(detachedTask, .deferredStart, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        manager.resetCalls()
        task.resetCallsAndStubs()
        detachedTask.resetCallsAndStubs()

        var actualTask = subject.complete(completion: {})
        XCTAssertTrue((actualTask as? FakeSmartTask) === task)
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo_Completionqueue_Completion, countSpecifier: .exactly(1))
        manager.resetCalls()

        actualTask = subject.complete(completion: { _ in })
        XCTAssertTrue((actualTask as? FakeSmartTask) === task)
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo_Completionqueue_Completion, countSpecifier: .exactly(1))
        manager.resetCalls()

        task.stub(.detach).andReturn(detachedTask)
        detachedTask.stub(.deferredStart).andReturn(detachedTask)

        let exp1 = expectation(description: "\(#function) wait 1")
        Task.detached {
            _ = await subject.async()
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 0.1)

        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(detachedTask, .deferredStart)
        XCTAssertHaveNotReceived(task, .detach)
        manager.resetCalls()
        detachedTask.resetCalls()
        task.resetCalls()

        let exp2 = expectation(description: "\(#function) wait 2")
        Task.detached {
            _ = try? await subject.decode(TestInfo.self).asyncWithThrowing()
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 0.1)

        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(detachedTask, .deferredStart)
        XCTAssertHaveNotReceived(task, .detach)

        manager.resetCallsAndStubs()
        task.resetCallsAndStubs()
        detachedTask.resetCallsAndStubs()
    }

    func test_variant() {
        let address: Address = .testMake()
        let parameters: Parameters = .testMake()
        let userInfo: UserInfo = .testMake()
        let manager: FakeRequestManager = .init()
        let subject = AnyRequest(pure: manager, address: address, parameters: parameters, userInfo: userInfo)
        XCTAssertNotNil(subject.void())
        XCTAssertNotNil(subject.json())
        XCTAssertNotNil(subject.data())
        XCTAssertNotNil(subject.image())

        XCTAssertNotNil(subject.decode(TestInfo.self, with: .init(), keyPath: []))

        manager.stub(.requestWithAddress_Parameters_Userinfo).andReturn(SmartResponse.testMake())

        let exp1 = expectation(description: "\(#function) wait 1")
        Task.detached {
            _ = await subject.decodeAsync(TestInfo.self, with: { .init() }, keyPath: [])
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 0.1)

        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo, countSpecifier: .atLeast(1))
        manager.resetCalls()

        let exp2 = expectation(description: "\(#function) wait 2")
        Task.detached {
            _ = try? await subject.decodeAsyncWithThrowing(TestInfo.self, with: { .init() }, keyPath: [])
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 0.1)

        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Userinfo, countSpecifier: .atLeast(1))
    }
}
#endif
