import Foundation

/// A deserializer that interprets response data as a JSON object.
///
/// Attempts to convert the response body into a Foundation-compatible `Any` type using `JSONSerialization`.
/// Suitable for endpoints that return unstructured or dynamic JSON content.
///
struct JSONContent: Deserializable {
    /// Decodes the response body into a Foundation JSON object.
    ///
    /// - Parameters:
    ///   - data: The `SmartResponse` containing the body and any error.
    ///   - parameters: The request parameters (unused).
    /// - Returns: A `.success` result containing the parsed JSON object or a `.failure` with an appropriate decoding error.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Any, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                return try .success(JSONSerialization.jsonObject(with: data))
            } catch {
                return .failure(error)
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
