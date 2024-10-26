import Foundation

/// A struct representing the response of a stubbed HTTP request.
public struct HTTPStubResponse {
    /// The status code of the response.
    public let statusCode: StatusCode
    /// The header fields of the response.
    public let header: HeaderFields
    /// The body of the response.
    public let body: HTTPStubBody
    /// The error that occurred during the request, if any.
    public let error: Error?
    public let delayInSeconds: TimeInterval?

    /// Initializes an HTTPStubResponse object with the provided parameters.
    public init(statusCode: StatusCode = 200,
                header: HeaderFields = [],
                body: HTTPStubBody = .empty,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }

    /// Initializes an HTTPStubResponse object with the provided parameters.
    public init(statusCode: StatusCode.Kind,
                header: HeaderFields = [],
                body: HTTPStubBody = .empty,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        let statusCode = StatusCode(statusCode)
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }

    /// Initializes an HTTPStubResponse object with the provided parameters.
    public init(statusCode: StatusCode.Kind,
                header: [String: String] = [:],
                body: HTTPStubBody = .empty,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        let statusCode = StatusCode(statusCode)
        self.statusCode = statusCode
        self.header = .init(header)
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }
}

#if swift(>=6.0)
extension HTTPStubResponse: Sendable {}
#endif
