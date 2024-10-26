import Foundation

public extension Data {
    func decode<T: Decodable>(_ type: T.Type, keyPath: String, decoder: JSONDecoder? = nil) throws -> T {
        return try decode(type, keyPath: [keyPath], decoder: decoder)
    }

    func decode<T: Decodable>(_ type: T.Type, keyPath: [String], decoder: JSONDecoder? = nil) throws -> T {
        let decoder = decoder ?? JSONDecoder()
        if keyPath.isEmpty {
            return try decoder.decode(type, from: self)
        }

        decoder.userInfo[.keyPath] = keyPath
        return try decoder.decode(ModelResponse<T>.self, from: self).nested
    }
}

/// Dummy model that handles model extracting logic from a key
private struct ModelResponse<NestedModel: Decodable>: Decodable {
    let nested: NestedModel

    public init(from decoder: Decoder) throws {
        // Split nested paths with '.'
        guard var keyPaths: [String] = decoder.userInfo[.keyPath] as? [String] else {
            throw RequestDecodingError.brokenResponse
        }

        // Get last key to extract in the end
        guard let lastKey: String = keyPaths.popLast() else {
            throw RequestDecodingError.brokenResponse
        }

        // Loop getting container until reach final one
        var targetContainer = try decoder.container(keyedBy: Key.self)
        for k in keyPaths {
            guard let key = Key(stringValue: k) else {
                throw RequestDecodingError.brokenResponse
            }
            targetContainer = try targetContainer.nestedContainer(keyedBy: Key.self, forKey: key)
        }

        guard let key = Key(stringValue: lastKey) else {
            throw RequestDecodingError.brokenResponse
        }
        self.nested = try targetContainer.decode(NestedModel.self, forKey: key)
    }
}

/// Dynamic key
private struct Key: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        return nil
    }
}

internal extension CodingUserInfoKey {
    static let keyPath: Self = .init(rawValue: "SmartNetwork.custom.keyPath")!
}
