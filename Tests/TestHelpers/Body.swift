import Foundation
import SpryKit

@testable import SmartNetwork

extension Body {
    var data: Data? {
        var request = URLRequest(url: .spry.testMake())
        try! (self as Self?).fill(&request)
        return request.httpBody
    }
}

extension Optional where Wrapped == Body {
    var data: Data? {
        self?.data
    }
}
