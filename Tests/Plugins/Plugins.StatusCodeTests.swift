#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class StatusCodePluginTests: XCTestCase {
    let session: FakeSmartURLSession = .init()

    func test_shouldNotIgnoreSuccess() async throws {
        let subject = Plugins.StatusCode(shouldIgnore200th: false, shouldIgnoreNil: false, shouldIgnorePreviousError: false)

        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 200)) }
        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 200)) }
        await assertThrows { try await subject.verify(response: .testMake(statusCode: 0)) }
        await assertThrows { try await subject.verify(response: .testMake(statusCode: -1)) }

        for code in StatusCode.Kind.allCases {
            await assertThrows(StatusCode(code), "\(code)") {
                try await subject.verify(response: .testMake(statusCode: code.rawValue))
            }
        }

        await assertThrows(StatusCode.noContent) { try await subject.verify(response: .testMake(statusCode: 204)) }
        await assertThrows(StatusCode(.badRequest)) { try await subject.verify(response: .testMake(statusCode: 400)) }
        await assertThrows(StatusCode(.notFound)) { try await subject.verify(response: .testMake(statusCode: 404)) }

        // shouldIgnorePreviousError
        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 304, error: RequestError.generic)) }
        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 400, error: RequestError.generic)) }
        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 404, error: RequestError.generic)) }

        // statusCode: nil
        await assertThrows(StatusCode.none) { try await subject.verify(response: .testMake()) }

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        try await subject.prepare(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        await subject.willSend(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        await subject.didReceive(parameters: .testMake(), userInfo: .testMake(), request: requestable, response: .testMake())
    }

    func test_shouldIgnoreSuccess() async throws {
        let subject = Plugins.StatusCode(shouldIgnore200th: true, shouldIgnoreNil: true, shouldIgnorePreviousError: true)

        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 200)) }
        await assertThrows { try await subject.verify(response: .testMake(statusCode: 0)) }
        await assertThrows { try await subject.verify(response: .testMake(statusCode: -1)) }

        for code in StatusCode.Kind.allCases {
            if (200..<300).contains(code.rawValue) {
                await assertNoThrow("\(code)") {
                    try await subject.verify(response: .testMake(statusCode: code.rawValue))
                }
            } else {
                await assertThrows(StatusCode(code), "\(code)") {
                    try await subject.verify(response: .testMake(statusCode: code.rawValue))
                }
            }
        }

        await assertNoThrow { try await subject.verify(response: .testMake(statusCode: 204)) }
        await assertThrows(StatusCode(.badRequest)) { try await subject.verify(response: .testMake(statusCode: 400)) }
        await assertThrows(StatusCode(.notFound)) { try await subject.verify(response: .testMake(statusCode: 404)) }

        // shouldIgnorePreviousError
        await assertThrows(StatusCode(.notModified)) { try await subject.verify(response: .testMake(statusCode: 304, error: RequestError.generic)) }
        await assertThrows(StatusCode(.badRequest)) { try await subject.verify(response: .testMake(statusCode: 400, error: RequestError.generic)) }
        await assertThrows(StatusCode(.notFound)) { try await subject.verify(response: .testMake(statusCode: 404, error: RequestError.generic)) }

        // statusCode: nil
        await assertNoThrow { try await subject.verify(response: .testMake()) }

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        try await subject.prepare(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        await subject.willSend(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        await subject.didReceive(parameters: .testMake(), userInfo: .testMake(), request: requestable, response: .testMake())
    }
}

private extension Plugin {
    func verify(response: SmartResponse) async throws {
        try await verify(parameters: .testMake(), userInfo: .testMake(), response: response)
    }
}

@inline(__always)
private func assertNoThrow(_ message: String = "",
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           _ block: () async throws -> Void) async {
    do {
        try await block()
    } catch {
        XCTFail(message.isEmpty ? "Unexpected error: \(error)" : message, file: file, line: line)
    }
}

@inline(__always)
private func assertThrows(_ expectedError: Error? = nil,
                          _ message: String = "",
                          file: StaticString = #filePath,
                          line: UInt = #line,
                          _ block: () async throws -> Void) async {
    do {
        try await block()
        XCTFail(message.isEmpty ? "Expected an error but got none" : message, file: file, line: line)
    } catch {
        if let expectedError {
            XCTAssertEqual(error as NSError, expectedError as NSError, file: file, line: line)
        }
    }
}
#endif
