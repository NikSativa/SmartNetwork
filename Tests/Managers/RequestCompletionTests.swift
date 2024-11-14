#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Combine
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class RequestCompletionTests: XCTestCase {
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let parameters: Parameters = .testMake()
    private let manager: FakeRequestManager = .init()
    private let task: FakeSmartTask = .init()

    var subject: any RequestCompletion<Result<Int, Error>> {
        return manager.request(address: address, parameters: parameters).decode(Int.self)
    }

    override func setUp() {
        super.setUp()
        manager.stub(.requestWithAddress_Parameters_Completionqueue_Completion).andDo { [task] args in
            if let completion = args[3] as? RequestManager.ResponseClosure {
                completion(RequestResult.testMake())
            }
            return task
        }
    }

    override func tearDown() {
        super.tearDown()
        manager.resetCallsAndStubs()
        task.resetCallsAndStubs()
    }

    func test_complete_queue_completion() {
        let _ = subject.complete(in: .async(Queue.main), completion: { _ in })
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_completion() {
        let _ = subject.complete(completion: { _ in })
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_oneWay() {
        task.stub(.detach).andReturn(task)
        task.stub(.deferredStart).andReturn(task)

        let _ = subject.oneWay()
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))

        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .deferredStart, countSpecifier: .atLeast(1))
    }

    func test_extension_complete_void() {
        let _ = subject.complete(completion: {})
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.async(Queue.main), Argument.closure, countSpecifier: .atLeast(1))
    }

    func test_extension_async() async {
        task.stub(.detach).andReturn(task)
        task.stub(.deferredStart).andReturn(task)

        let _ = await subject.async()
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.absent, Argument.closure, countSpecifier: .atLeast(1))

        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .deferredStart, countSpecifier: .atLeast(1))
    }

    func test_extension_asyncWithThrowing() async throws {
        task.stub(.detach).andReturn(task)
        task.stub(.deferredStart).andReturn(task)

        let _ = try? await subject.asyncWithThrowing()
        XCTAssertHaveReceived(manager, .requestWithAddress_Parameters_Completionqueue_Completion, with: address, parameters, DelayedQueue.absent, Argument.closure, countSpecifier: .atLeast(1))

        XCTAssertHaveReceived(task, .detach, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(task, .deferredStart, countSpecifier: .atLeast(1))
    }
}
#endif
