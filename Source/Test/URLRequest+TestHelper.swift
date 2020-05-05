import Foundation
import Spry
import Nimble
import Spry_Nimble

import NRequest

extension URLRequest: SpryEquatable, TestOutputStringConvertible {
    static func testMake(url: URL = .testMake(),
                         headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    public var testDescription: String {
        [String(describing: type(of: self)), self.description, String(describing: allHTTPHeaderFields)].compactMap({ $0 }).joined(separator: ", ")
    }
}
