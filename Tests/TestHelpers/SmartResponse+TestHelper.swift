import Foundation
import SmartNetwork
import SpryKit

// MARK: - SmartResponse + Equatable, SpryEquatable

extension SmartResponse: Equatable, SpryEquatable {
    public static func testMake(url: URL = .spry.testMake(),
                                statusCode: Int,
                                httpVersion: String? = nil,
                                headerFields: [String: String]? = nil,
                                body: Body? = nil,
                                error: Error? = nil,
                                session: SmartURLSession = SmartNetworkSettings.sharedSession) -> Self {
        var request = URLRequest(url: url)
        for field in headerFields ?? [:] {
            request.addValue(field.value, forHTTPHeaderField: field.key)
        }
        request.httpBody = try? body?.encode().httpBody
        return .init(request: request,
                     body: request.httpBody,
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
                                session: SmartURLSession = SmartNetworkSettings.sharedSession) -> Self {
        return .init(request: request,
                     body: try? body?.encode().httpBody,
                     response: response,
                     error: error,
                     session: session)
    }

    public static func ==(lhs: SmartResponse, rhs: SmartResponse) -> Bool {
        return lhs.request?.sdk == rhs.request?.sdk &&
            lhs.body == rhs.body &&
            lhs.response?.url == rhs.response?.url &&
            (lhs.error as NSError?) == (rhs.error as NSError?)
    }
}
