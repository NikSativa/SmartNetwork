#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Combine
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class RequestCompletionTests: XCTestCase {
    private let url: SmartURL = .testMake(string: "http://example1.com/signin")
    private let parameters: Parameters = .testMake()
    private let manager: FakeRequestManager = .init()
    private let task: FakeSmartTask = .init()

    var subject: any RequestCompletion<Result<Int, Error>> {
        return manager.request(url: url, parameters: parameters).decode(Int.self)
    }

    override func setUp() {
        super.setUp()
        manager.stub(.requestWithUrl_Parameters_Userinfo_Completionqueue_Completion).andDo { [task] args in
            if let completion = args[4] as? RequestManager.ResponseClosure {
                completion(SmartResponse.testMake())
            }
            return task
        }

        manager.stub(.requestWithUrl_Parameters_Userinfo).andReturn(SmartResponse.testMake())
    }

    override func tearDown() {
        super.tearDown()
        manager.resetCallsAndStubs()
        task.resetCallsAndStubs()
    }

    func test_complete_queue_completion() {
        _ = subject.complete(in: .async(Queue.main), completion: { _ in })
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo_Completionqueue_Completion, with: url, parameters, Argument.anything, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_completion() {
        _ = subject.complete(completion: { _ in })
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo_Completionqueue_Completion, with: url, parameters, Argument.anything, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_oneWay() {
        task.stub(.detach).andReturn(task)
        task.stub(.deferredStart).andReturn(task)

        _ = subject.oneWay()
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo_Completionqueue_Completion, with: url, parameters, Argument.anything, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))

        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .deferredStart, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_void() {
        _ = subject.complete(completion: {})
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo_Completionqueue_Completion, with: url, parameters, Argument.anything, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_async() async {
        _ = await subject.async()
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo, with: url, parameters, Argument.anything, countSpecifier: .atLeast(1))
    }

    func test_extension_asyncWithThrowing() async {
        _ = try? await subject.asyncWithThrowing()
        XCTAssertHaveReceived(manager, .requestWithUrl_Parameters_Userinfo, with: url, parameters, Argument.anything, countSpecifier: .atLeast(1))
    }
}
#endif
