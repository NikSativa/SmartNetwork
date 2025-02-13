import Foundation

/// A protocol for deserialising of response data.
public protocol Deserializable<Object> {
    /// An associated type `Object` to specify the decoded object type.
    associatedtype Object

    /// Implement this method to customize decoding behavior for specific data types.
    ///
    /// - Parameters:
    ///   - data: The data to be decoded.
    ///   - decoder: *(if needed)* An autoclosure providing a ``JSONDecoder`` instance for decoding that was specified in ``Parameters``.
    ///
    /// - Returns: A Result object containing the decoded object or an error.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Object, Error>
}
