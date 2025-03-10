import Foundation

public extension Data {
    /// Decode data with keyPath and return a Decodable object of the given type.
    func decode<T: Decodable>(_ type: T.Type, keyPath: String, decoder: JSONDecoder? = nil) throws -> T {
        return try decode(type, keyPath: [keyPath], decoder: decoder)
    }

    /// Decode data with keyPath and return a Decodable object of the given type. If keyPath is empty, it will decode the data directly.
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
            throw RequestDecodingError.brokenKeyPath("KeyPath not found")
        }

        // Get last key to extract in the end
        guard let lastKey: String = keyPaths.popLast() else {
            throw RequestDecodingError.brokenKeyPath("KeyPath is empty")
        }

        // Loop getting container until reach final one
        var targetContainer = try decoder.container(keyedBy: Key.self)
        for key in keyPaths {
            guard let key = Key(stringValue: key) else {
                throw RequestDecodingError.brokenKeyPath(key)
            }
            targetContainer = try targetContainer.nestedContainer(keyedBy: Key.self, forKey: key)
        }

        // Extract final model
        guard let key = Key(stringValue: lastKey) else {
            throw RequestDecodingError.brokenKeyPath(lastKey)
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
