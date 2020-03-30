import Foundation
import Spry

import NRequest

extension URL: SpryEquatable {
    public static func testMake(string: String = "") -> URL {
        return URL(string: string)!
    }
}
