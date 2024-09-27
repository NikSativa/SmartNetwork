import Foundation
import SpryKit

@testable import SmartNetwork

extension RequestResult: Equatable, SpryEquatable {
    public static func testMake(url: URL = .spry.testMake(),
                                statusCode: Int,
                                httpVersion: String? = nil,
                                headerFields: [String: String]? = nil,
                                body: Data? = nil,
                                error: Error? = nil) -> Self {
        return .init(request: URLRequest(url: url),
                     body: body,
                     response: HTTPURLResponse(url: url,
                                               statusCode: statusCode,
                                               httpVersion: httpVersion,
                                               headerFields: headerFields),
                     error: error)
    }

    public static func testMake(request: URLRequestRepresentation? = nil,
                                body: Data? = nil,
                                response: URLResponse? = nil,
                                error: Error? = nil) -> Self {
        return .init(request: request,
                     body: body,
                     response: response,
                     error: error)
    }

    public static func ==(lhs: RequestResult, rhs: RequestResult) -> Bool {
        return lhs.request?.sdk == rhs.request?.sdk &&
            lhs.body == rhs.body &&
            lhs.response == rhs.response &&
            (lhs.error as NSError?) == (rhs.error as NSError?)
    }
}
