import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestableTests: XCTestCase {
    func test_request() {
        var responses: [RequestResult] = []
        let task: FakeSessionTask = .init()
        let session: FakeSession = .init()
        let parameters: Parameters = .testMake(queue: .absent,
                                               session: session)

        let sdkRequst = URLRequest.testMake(url: "google.com")
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequst)

        let subject: Requestable = Request.create(with: parameters, urlRequestable: urlRequestable)
        subject.completion = { data in
            responses.append(data)
        }
        XCTAssertEqual(subject.parameters, parameters)

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        subject.start()
        XCTAssertHaveReceived(task, .resume)
        XCTAssertHaveReceived(session, .task)

        // cancel
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()

        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()
        subject.cancel()

        XCTAssertHaveReceived(task, .isRunning)
        XCTAssertHaveReceived(task, .cancel)
        XCTAssertTrue(responses.isEmpty)

        // reset everything before start again
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()

        // create new task and retain it
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        // start again
        subject.start()

        XCTAssertHaveReceived(task, .resume, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(session, .task)

        // should stop task before triggering response
        task.stub(.cancel).andReturn()
        task.stub(.isRunning).andReturn(true)

        // receive response
        session.completionHandler?(nil, nil, nil)

        XCTAssertEqual(responses, [.testMake(request: sdkRequst)])
        XCTAssertHaveReceived(task, .cancel, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(task, .isRunning, countSpecifier: .exactly(1))

        // impossible behavior, but expected that response can be received more then once
        session.completionHandler?(nil, nil, nil)
        XCTAssertEqual(responses, [.testMake(request: sdkRequst), .testMake(request: sdkRequst)])
    }
}
