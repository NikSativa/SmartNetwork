import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class PluginsTokenPluginTests: XCTestCase {
    let session: FakeSmartURLSession = .init()

    func test_header_addToken() {
        XCTAssertCheckToken(.header(.add(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.header(.add(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.header(.add(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        XCTAssertCheckToken(.header(.add(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_header_setToken() {
        XCTAssertCheckToken(.header(.set(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.header(.set(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.header(.set(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        XCTAssertCheckToken(.header(.set(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_query_addToken() {
        XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_query_setToken() {
        XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: nil, url: Constant.url, session: session)
    }
}

private typealias TokenType = Plugins.TokenType
private enum Constant {
    static let value = "my_token_string"
    static let key = "my_token_key"

    static let url = URL.spry.testMake("https://www.apple.com")
    static let urlWithQuery = URL.spry.testMake("https://www.apple.com?my_token_key=broken_token_string")
}

@inline(__always)
private func XCTAssertCheckToken(_ type: Plugins.TokenType,
                                 value: String?,
                                 url: URL,
                                 session: FakeSmartURLSession,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
    let request: FakeURLRequestRepresentation = .init()
    switch type {
    case .header(let operation):
        switch operation {
        case .add(let key):
            request.stub(.addValue).with(value ?? Argument.nil, key).andReturn()
        case .set(let key):
            request.stub(.setValue).with(value ?? Argument.nil, key).andReturn()
        }
    case .queryParam:
        request.stub(.url).andReturn(url)
    }

    let subject: Plugins.TokenPlugin = .init(id: "test.token", priority: 0, type: type) {
        return value
    }

    let parameters: Parameters = .testMake()
    subject.prepare(parameters, request: request, session: session)

    XCTAssertTrue(parameters.userInfo.isEmpty)

    switch type {
    case .header(let operation):
        switch operation {
        case .add(let key):
            if let value {
                XCTAssertHaveReceived(request, .addValue, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
            } else {
                XCTAssertHaveNoRecordedCalls(request, file: file, line: line)
            }
        case .set(let key):
            XCTAssertHaveReceived(request, .setValue, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
        }
    case .queryParam(let operation):
        let newUrl: String
        switch operation {
        case .set(let key):
            let newParam = [key, value].filterNils().joined(separator: "=")
            if url == Constant.url {
                newUrl = [url.absoluteString, "?", newParam].joined()
            } else {
                newUrl = url.absoluteString.replacingOccurrences(of: "my_token_key=broken_token_string", with: newParam)
            }
        case .add(let key):
            let newParam = [key, value].filterNils().joined(separator: "=")
            if url == Constant.url {
                newUrl = [url.absoluteString, "?", newParam].joined()
            } else {
                newUrl = [url.absoluteString, "&", newParam].joined()
            }
        }

        XCTAssertHaveReceived(request, .url, with: URL.spry.testMake(newUrl), countSpecifier: .exactly(1), file: file, line: line)
    }

    let data: RequestResult = .testMake()
    XCTAssertNoThrowError(try subject.verify(data: data, userInfo: parameters.userInfo))
    XCTAssertTrue(data.allHeaderFields.isEmpty)
}
