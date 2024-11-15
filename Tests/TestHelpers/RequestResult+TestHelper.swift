import Foundation
import SpryKit

@testable import SmartNetwork

// MARK: - RequestResult + Equatable, SpryEquatable

extension RequestResult: Equatable, SpryEquatable {
    public static func testMake(url: URL = .spry.testMake(),
                                statusCode: Int,
                                httpVersion: String? = nil,
                                headerFields: [String: String]? = nil,
                                body: Body? = nil,
                                error: Error? = nil,
                                session: SmartURLSession = RequestSettings.sharedSession) -> Self {
        var request = URLRequest(url: url)
        for field in headerFields ?? [:] {
            request.addValue(field.value, forHTTPHeaderField: field.key)
        }
        request.httpBody = body.data
        return .init(request: request,
                     body: body.data,
                     response: HTTPURLResponse(url: url,
                                               statusCode: statusCode,
                                               httpVersion: httpVersion,
                                               headerFields: headerFields),
                     error: error,
                     session: session)
    }

    public static func testMake(request: URLRequestRepresentation? = nil,
                                body: Body? = nil,
                                response: URLResponse? = nil,
                                error: Error? = nil,
                                session: SmartURLSession = RequestSettings.sharedSession) -> Self {
        return .init(request: request,
                     body: body.data,
                     response: response,
                     error: error,
                     session: session)
    }

    public static func ==(lhs: RequestResult, rhs: RequestResult) -> Bool {
        return lhs.request?.sdk == rhs.request?.sdk &&
            lhs.body == rhs.body &&
            lhs.response == rhs.response &&
            (lhs.error as NSError?) == (rhs.error as NSError?)
    }
}
