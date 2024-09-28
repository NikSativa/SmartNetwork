import Foundation
import SmartNetwork
import SpryKit

// MARK: - Body + Equatable, SpryEquatable

extension Body: Equatable, SpryEquatable {
    private static func compare(_ lhs: Any, _ rhs: Any) -> Bool {
        return isAnyEqual(lhs, rhs)
    }

    private static func compare(_ lhs: any Encodable, _ rhs: any Encodable) -> Bool {
        return isAnyEqual(lhs, rhs)
    }

    public static func ==(lhs: Body, rhs: Body) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.data(let a), .data(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            return a == b
        case (.encodable(let a), .encodable(let b)):
            return compare(a, b)
        case (.form(let a), .form(let b)):
            return a == b
        case (.xform(let a), .xform(let b)):
            return compare(a, b)
        case (.json(let a, let o1), .json(let b, let o2)):
            return compare(a, b) && o1 == o2

        case (.data, _),
             (.empty, _),
             (.encodable, _),
             (.form, _),
             (.image, _),
             (.json, _),
             (.xform, _):
            return false
        }
    }
}

extension Body.ImageFormat: SpryEquatable {}

extension Body.Form: SpryEquatable {}
extension Body.Form.MimeType: SpryEquatable {}

private extension Encodable {
    func string() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
