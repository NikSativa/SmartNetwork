import Foundation
import NSpry

@testable import NRequest

extension ResponseData: Equatable, SpryEquatable {
    public static func testMake(url: URL = .testMake(),
                                statusCode: Int,
                                httpVersion: String? = nil,
                                headerFields: [String: String]? = nil,
                                body: Data? = nil,
                                error: Error? = nil) -> Self {
        return .init(request: Impl.URLRequestable(URLRequest(url: url)),
                     body: body,
                     response: HTTPURLResponse(url: url,
                                               statusCode: statusCode,
                                               httpVersion: httpVersion,
                                               headerFields: headerFields),
                     error: error)
    }

    public static func testMake(request: URLRequestable? = nil,
                                body: Data? = nil,
                                response: URLResponse? = nil,
                                error: Error? = nil) -> Self {
        return .init(request: request,
                     body: body,
                     response: response,
                     error: error)
    }

    public static func ==(lhs: ResponseData, rhs: ResponseData) -> Bool {
        return lhs.body == rhs.body &&
            lhs.response == rhs.response &&
            (lhs.error as NSError?) == (rhs.error as NSError?)
    }
}
