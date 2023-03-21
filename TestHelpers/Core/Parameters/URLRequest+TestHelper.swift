import Foundation
import NRequest
import NSpry

// MARK: - URLRequest + SpryEquatable

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

public extension URLRequest {
    var testDescription: String {
        return [
            String(describing: type(of: self)),
            description,
            String(describing: allHTTPHeaderFields)
        ].compactMap { $0 }.joined(separator: ", ")
    }
}
