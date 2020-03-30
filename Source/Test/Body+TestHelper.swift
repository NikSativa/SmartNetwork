import Foundation
import Spry

import NRequest

extension Body: Equatable, SpryEquatable {
    private static func compare(_ lhs: Any, _ rhs: Any) -> Bool {
        guard JSONSerialization.isValidJSONObject(lhs) else {
            return false
        }

        guard JSONSerialization.isValidJSONObject(rhs) else {
            return false
        }

        let dataA = try? JSONSerialization.data(withJSONObject: lhs, options: [])
        let dataB = try? JSONSerialization.data(withJSONObject: rhs, options: [])
        return dataA == dataB
    }

    public static func ==(lhs: Body, rhs: Body) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.json(let a), .json(let b)):
            return compare(a, b)
        case (.data(let a), .data(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            return a == b
        case (.encodable(let a), .encodable(let b)):
            return a == b
        case (.form(let a), .form(let b)):
            return a == b
        case (.xform(let a), .xform(let b)):
            return compare(a, b)

        case (.empty, _),
             (.json, _),
             (.data, _),
             (.image, _),
             (.encodable, _),
             (.form, _),
             (.xform, _):
            return false
        }
    }
}

extension Body.AnyEncodable: Equatable, SpryEquatable {
    public static func ==(lhs: Body.AnyEncodable, rhs: Body.AnyEncodable) -> Bool {
        let encoder = JSONEncoder()
        let a = try? encoder.encode(lhs)
        let b = try? encoder.encode(rhs)
        return a != nil && a == b
    }
}

extension Body.Image: SpryEquatable { }
extension Body.Form: SpryEquatable { }
