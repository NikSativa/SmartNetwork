import Foundation
import Spry

import NRequest

extension URL: SpryEquatable {
    static func testMake(string: String = "http://www.some.com") -> URL {
        return URL(string: string)!
    }
}
