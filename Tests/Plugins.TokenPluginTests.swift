import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class PluginsTokenPluginTests: XCTestCase {
    func test_addToken() {
        XCTAssertCheckToken(.header(.add(Constant.key)), value: Constant.value)
        XCTAssertCheckToken(.header(.add(Constant.key)), value: nil)
    }

    func test_setToken() {
        XCTAssertCheckToken(.header(.set(Constant.key)), value: Constant.value)
        XCTAssertCheckToken(.header(.set(Constant.key)), value: nil)
    }

    func test_queryParam() {
        XCTAssertCheckToken(.queryParam(Constant.key), value: Constant.value)
        XCTAssertCheckToken(.queryParam(Constant.key), value: nil)
    }
}

private typealias TokenType = Plugins.TokenType
private enum Constant {
    static let type = "type"
    static let url = URL.testMake("http://www.google.com/?my_token_key=broken_token_string")
    static let value = "my_token_string"
    static let key = "my_token_key"
}

@inline(__always)
private func XCTAssertCheckToken(_ type: Plugins.TokenType,
                                 value: String?,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
    let request: FakeURLRequestRepresentation = .init()
    switch type {
    case .header(let operation):
        switch operation {
        case .add(let key):
            request.stub(.addValue).with(value, key).andReturn()
        case .set(let key):
            request.stub(.setValue).with(value, key).andReturn()
        }
    case .queryParam:
        request.stub(.url).andReturn(Constant.url)
    }

    let subject: Plugins.TokenPlugin = .init(type: type) {
        return value
    }

    var userInfo: Parameters.UserInfo = .init()
    let parameters: Parameters = .testMake()
    subject.prepare(parameters,
                    request: request,
                    userInfo: &userInfo)

    XCTAssertTrue(userInfo.isEmpty)

    if let value {
        XCTAssertHaveRecordedCalls(request, file: file, line: line)
        switch type {
        case .header(let operation):
            switch operation {
            case .add(let key):
                XCTAssertHaveReceived(request, .addValue, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
            case .set(let key):
                XCTAssertHaveReceived(request, .setValue, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
            }
        case .queryParam(let key):
            let newUrl = [
                Constant.url.absoluteString.replacingOccurrences(of: "?my_token_key=broken_token_string", with: ""),
                "?", key, "=", value
            ].joined()
            XCTAssertHaveReceived(request, .url, with: URL.testMake(newUrl), countSpecifier: .exactly(1), file: file, line: line)
        }
    } else {
        XCTAssertHaveNotRecordedCalls(request, file: file, line: line)
    }

    XCTAssertNotThrowsError(try subject.verify(data: .testMake(), userInfo: userInfo))
}
