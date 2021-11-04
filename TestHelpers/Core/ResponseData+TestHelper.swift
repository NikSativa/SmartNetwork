import Foundation
import NSpry

@testable import NRequest

extension ResponseData: Equatable, SpryEquatable {
    public static func testMake(url: URL = .testMake(),
                                statusCode: Int,
                                httpVersion: String? = nil,
                                headerFields: [String: String]? = nil,
                                body: Data? = nil,
                                error: Error? = nil,
                                userInfo: Parameters.UserInfo = .init()) -> Self {
        return .init(body: body,
                     response: HTTPURLResponse(url: url,
                                               statusCode: statusCode,
                                               httpVersion: httpVersion,
                                               headerFields: headerFields),
                     error: error,
                     userInfo: userInfo)
    }

    public static func testMake(body: Data? = nil,
                                response: URLResponse? = nil,
                                error: Error? = nil,
                                userInfo: Parameters.UserInfo = .init()) -> Self {
        return .init(body: body,
                     response: response,
                     error: error,
                     userInfo: userInfo)
    }

    public static func ==(lhs: ResponseData, rhs: ResponseData) -> Bool {
        return lhs.body == rhs.body &&
            lhs.response == rhs.response &&
            (lhs.error as NSError?) == (rhs.error as NSError?) &&
            lhs.userInfo == rhs.userInfo
    }
}
