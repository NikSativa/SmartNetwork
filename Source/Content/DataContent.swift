import Foundation

/// A deserializer that extracts raw `Data` from a `SmartResponse`.
///
/// This is used when the expected output is unprocessed binary data. If the response
/// includes an error or is missing a body, decoding will fail.
struct DataContent: Deserializable {
    /// Attempts to extract the raw body data from a `SmartResponse`.
    ///
    /// - Parameters:
    ///   - data: The response to decode, including body and error.
    ///   - parameters: Request parameters (unused here).
    /// - Returns: A result containing the response body as `Data`, or an error if unavailable.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Data, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            return .success(data)
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
