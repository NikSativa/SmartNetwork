import Foundation

public extension Data {
    /// Decodes JSON data into a `Decodable` object using a single key path component.
    ///
    /// This overload is a convenience method for accessing a nested object using one string key.
    ///
    /// - Parameters:
    ///   - type: The expected `Decodable` type to decode.
    ///   - keyPath: A string representing the key used to locate the nested object.
    ///   - decoder: An optional `JSONDecoder` to use. Defaults to `JSONDecoder()`.
    /// - Returns: The decoded object of the specified type.
    /// - Throws: An error if decoding fails or the key path is invalid.
    func decode<T: Decodable>(_ type: T.Type, keyPath: String, decoder: JSONDecoder? = nil) throws -> T {
        return try decode(type, keyPath: [keyPath], decoder: decoder)
    }

    /// Decodes JSON data into a `Decodable` object using a sequence of key path components.
    ///
    /// This function allows decoding deeply nested objects using a chain of keys. If the key path is empty,
    /// decoding occurs directly at the root level.
    ///
    /// - Parameters:
    ///   - type: The expected `Decodable` type to decode.
    ///   - keyPath: An array of strings representing the path to the nested object.
    ///   - decoder: An optional `JSONDecoder` to use. Defaults to `JSONDecoder()`.
    /// - Returns: The decoded object of the specified type.
    /// - Throws: An error if decoding fails or the key path is invalid.
    func decode<T: Decodable>(_ type: T.Type, keyPath: [String], decoder: JSONDecoder? = nil) throws -> T {
        let decoder = decoder ?? JSONDecoder()
        if keyPath.isEmpty {
            return try decoder.decode(type, from: self)
        }

        decoder.userInfo[.keyPath] = keyPath
        return try decoder.decode(ModelResponse<T>.self, from: self).nested
    }
}

/// A helper model that extracts a nested decodable object using a key path during decoding.
///
/// This type is used internally to traverse nested containers using a dynamic key path
/// and decode the final object of interest.
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

/// A dynamic coding key used to traverse JSON containers based on string keys.
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
    /// A user info key used to pass the decoding key path into the decoder context.
    static let keyPath: Self = .init(rawValue: "SmartNetwork.custom.keyPath")!
}
