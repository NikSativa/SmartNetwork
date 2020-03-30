import Foundation
import Spry

import NRequest

extension URLRequest {
    public static func testMake(url: URL = .testMake()) -> URLRequest {
        return URLRequest(url: url)
    }
}
