#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SpryKit
import XCTest
@testable import SmartNetwork

final class PluginsTokenPluginTests: XCTestCase {
    let session: FakeSmartURLSession = .init()

    func test_header_addToken() async {
        await XCTAssertCheckToken(.header(.add(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.header(.add(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.header(.add(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        await XCTAssertCheckToken(.header(.add(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_header_setToken() async {
        await XCTAssertCheckToken(.header(.set(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.header(.set(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.header(.set(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        await XCTAssertCheckToken(.header(.set(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_query_addToken() async {
        await XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        await XCTAssertCheckToken(.queryParam(.add(Constant.key)), value: nil, url: Constant.url, session: session)
    }

    func test_query_setToken() async {
        await XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: Constant.value, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: nil, url: Constant.urlWithQuery, session: session)
        await XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: Constant.value, url: Constant.url, session: session)
        await XCTAssertCheckToken(.queryParam(.set(Constant.key)), value: nil, url: Constant.url, session: session)
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
                                 line: UInt = #line) async {
    let request: FakeURLRequestRepresentation = .init()
    switch type {
    case .header(let operation):
        switch operation {
        case .add(let key):
            request.stub(.addValueWithValue_Forhttpheaderfield).with(value ?? Argument.nil, key).andReturn()
        case .set(let key):
            request.stub(.setValueWithValue_Forhttpheaderfield).with(value ?? Argument.nil, key).andReturn()
        case .trySet(let key):
            request.stub(.setValueWithValue_Forhttpheaderfield).with(value ?? Argument.nil, key).andReturn()
        }

    case .queryParam:
        request.stub(.url_get).andReturn(url)
        request.stub(.url_set).andReturn()
    }

    let subject: Plugins.TokenPlugin = .init(id: "test.token", priority: 0, type: type) {
        return value
    }

    let parameters: Parameters = .testMake()
    let userInfo: UserInfo = .testMake()
    await subject.prepare(parameters: parameters, userInfo: userInfo, request: request, session: session)
    XCTAssertTrue(userInfo.isEmpty)

    switch type {
    case .header(let operation):
        switch operation {
        case .add(let key):
            if let value {
                XCTAssertHaveReceived(request, .addValueWithValue_Forhttpheaderfield, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
            } else {
                XCTAssertHaveNoRecordedCalls(request, file: file, line: line)
            }

        case .set(let key):
            XCTAssertHaveReceived(request, .setValueWithValue_Forhttpheaderfield, with: value, key, countSpecifier: .exactly(1), file: file, line: line)

        case .trySet(let key):
            XCTAssertHaveReceived(request, .setValueWithValue_Forhttpheaderfield, with: value, key, countSpecifier: .exactly(1), file: file, line: line)
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

        case .trySet(let key):
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

        XCTAssertHaveReceived(request, .url_set, with: URL.spry.testMake(newUrl), countSpecifier: .exactly(1), file: file, line: line)
    }

    let data: SmartResponse = .testMake()
    XCTAssertNoThrowError(try subject.verify(parameters: parameters, userInfo: .testMake(), data: data))
    XCTAssertTrue(data.allHeaderFields.isEmpty)
}
#endif
