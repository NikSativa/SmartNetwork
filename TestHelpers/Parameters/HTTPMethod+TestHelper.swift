import Foundation
import Spry

import NRequest

extension HTTPMethod: Equatable, SpryEquatable {
    public static func ==(lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {
        switch (lhs, rhs) {
        case (.delete, .delete),
             (.put, .put),
             (.get, .get):
            return true
        case (.post(let a), .post(let b)):
            return a == b

        case (.delete, _),
             (.put, _),
             (.get, _),
             (.post, _):
            return false
        }
    }
}
