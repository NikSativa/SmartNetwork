import Foundation

/// Represents a stubbed HTTP response used for testing network behavior.
///
/// `HTTPStubResponse` allows simulation of server responses with configurable status code, headers, body content,
/// errors, and optional response delays.
public struct HTTPStubResponse: SmartSendable {
    /// The status code of the response.
    public let statusCode: StatusCode
    /// The header fields of the response.
    public let header: HeaderFields
    /// The body of the response.
    public let body: HTTPStubBody?
    /// The error that occurred during the request, if any.
    public let error: Error?
    public let delayInSeconds: TimeInterval?

    /// Creates a new stubbed response with an explicit status code.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code (e.g. 200, 404).
    ///   - header: The response headers.
    ///   - body: The optional body content.
    ///   - error: An optional error to simulate network failure.
    ///   - delayInSeconds: An optional delay before delivering the response.
    public init(statusCode: StatusCode = 200,
                header: HeaderFields = [:],
                body: HTTPStubBody? = nil,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }

    /// Creates a new stubbed response using a `StatusCode.Kind`.
    ///
    /// - Parameters:
    ///   - statusCode: The semantic status code (e.g. `.ok`, `.notFound`).
    ///   - header: The response headers.
    ///   - body: The optional body content.
    ///   - error: An optional error to simulate network failure.
    ///   - delayInSeconds: An optional delay before delivering the response.
    public init(statusCode: StatusCode.Kind,
                header: HeaderFields = [:],
                body: HTTPStubBody? = nil,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        let statusCode = StatusCode(statusCode)
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }

    /// Builds a `URLResponse` object from the stubbed response, using the specified URL.
    ///
    /// - Parameter url: The URL to associate with the response.
    /// - Returns: An `HTTPURLResponse` if possible, or a generic `URLResponse` fallback.
    internal func urlResponse(url: URL) -> URLResponse {
        let response = HTTPURLResponse(url: url,
                                       statusCode: statusCode.code,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: header.mapToResponse())
        return response ?? URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
    }
}
