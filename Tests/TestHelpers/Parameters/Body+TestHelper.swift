import Foundation
import SmartNetwork
import SpryKit

// MARK: - Body + Equatable

extension HTTPBody: Equatable {
    private static func compare(_ lhs: Any, _ rhs: Any) -> Bool {
        return isAnyEqual(lhs, rhs)
    }

    private static func compare(_ lhs: any Encodable, _ rhs: any Encodable) -> Bool {
        return isAnyEqual(lhs, rhs)
    }

    public static func ==(lhs: HTTPBody, rhs: HTTPBody) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case let (.data(a, contentTypeA), .data(b, contentTypeB)):
            return a == b && contentTypeA == contentTypeB
        case let (.image(a), .image(b)):
            return a.contentType == b.contentType && (try? a.data()) == (try? b.data())
        case let (.encode(a, _), .encode(b, _)):
            return compare(a, b)
        case let (.form(a), .form(b)):
            return a == b
        case let (.xform(a), .xform(b)):
            return compare(a, b)
        case let (.json(a, o1), .json(b, o2)):
            return compare(a, b) && o1 == o2
        case (.data, _),
             (.empty, _),
             (.encode, _),
             (.form, _),
             (.image, _),
             (.json, _),
             (.xform, _):
            return false
        }
    }
}

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
