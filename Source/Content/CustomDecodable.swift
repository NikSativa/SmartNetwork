import Foundation

/// A protocol for custom decoding of data objects.
public protocol CustomDecodable {
    /// An associated type `Object` to specify the decoded object type.
    associatedtype Object

    /// Implement this method to customize decoding behavior for specific data types.
    ///
    /// - Parameters:
    ///   - data: The data to be decoded.
    ///   - decoder: *(if needed)* An autoclosure providing a ``JSONDecoder`` instance for decoding that was specified in ``Parameters``.
    ///
    /// - Returns: A Result object containing the decoded object or an error.
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Object, Error>
}
