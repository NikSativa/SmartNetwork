import Foundation
import Nimble
import NSpry

import NRequest

extension URLRequest: TestOutputStringConvertible {
    public var testDescription: String {
        return [String(describing: type(of: self)),
                description,
                String(describing: allHTTPHeaderFields)].compactMap { $0 }.joined(separator: ", ")
    }
}
