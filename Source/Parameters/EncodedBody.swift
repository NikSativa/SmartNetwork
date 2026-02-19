import Foundation

/// Represents the result of encoding a `Body` instance into data and HTTP headers.
public struct EncodedBody {
    /// Encoded HTTP body bytes.
    public let httpBody: Data?
    /// Headers required for encoded body (`Content-Type`, `Content-Length`, etc.).
    public let headers: HeaderFields

    /// Creates encoded body container.
    ///
    /// - Parameters:
    ///   - httpBody: Encoded bytes.
    ///   - headers: Associated headers.
    public init(httpBody: Data?, _ headers: HeaderFields) {
        self.httpBody = httpBody
        self.headers = headers
    }

    /// Populates the given URL request with the encoded body and its associated headers.
    ///
    /// - Parameter request: The request to modify.
    public func fill(_ request: inout URLRequest) {
        request.httpBody = httpBody
        for item in headers {
            if request.value(forHTTPHeaderField: item.key) == nil {
                request.setValue(item.value, forHTTPHeaderField: item.key)
            }
        }
    }
}

#if swift(>=6.0)
extension EncodedBody: Sendable {}
#endif
