import Foundation
import NRequest
import NSpry

extension URLRequest: SpryEquatable {
    public static func testMake(url: String,
                                headers: [String: String] = [:]) -> URLRequest {
        return .testMake(url: URL.testMake(url),
                         headers: headers)
    }

    public static func testMake(url: URL = .testMake(),
                                headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}
