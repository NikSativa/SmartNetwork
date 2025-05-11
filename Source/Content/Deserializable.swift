import Foundation

/// A protocol for decoding response data into a strongly typed object.
///
/// Conforming types define how to transform raw `SmartResponse` data into a specific output type.
/// This protocol enables flexible decoding logic for different data formats or content structures.
public protocol Deserializable<Object> {
    /// The type that the response data will be decoded into.
    associatedtype Object

    /// Decodes the given response into a strongly typed result.
    ///
    /// - Parameters:
    ///   - data: The response to decode, including body data and metadata.
    ///   - parameters: The request parameters, which may contain decoding preferences.
    /// - Returns: A `Result` containing either the decoded object or an error.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Object, Error>
}
