import Foundation
import NSpry

import NRequest

extension URL: SpryEquatable {
    public static func testMake(_ string: String = "http://www.some.com") -> URL {
        return URL(string: string).unsafelyUnwrapped
    }
}
