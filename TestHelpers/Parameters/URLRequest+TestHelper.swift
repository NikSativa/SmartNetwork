import Foundation
import NSpry
import Nimble

import NRequest

extension URLRequest: SpryEquatable, TestOutputStringConvertible {
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

    public var testDescription: String {
        return [String(describing: type(of: self)),
                self.description,
                String(describing: allHTTPHeaderFields)].compactMap({ $0 }).joined(separator: ", ")
    }
}
