import Foundation
import os

@available(*, deprecated, renamed: "SmartResponse", message: "Use 'SmartResponse' instead.")
typealias RequestResult = SmartResponse

/// Encapsulates the result of a network request, including request metadata, response data, and error information.
///
/// `SmartResponse` provides a structured representation of a completed network transaction, including access to
/// the original request, response headers, HTTP status code, body content, and any associated error.
public final class SmartResponse {
    /// The original ``URLRequestRepresentation`` made for the request.
    public let request: URLRequestRepresentation?

    /// The body ``Data`` of the response.
    public let body: Data?

    /// The ``URLResponse`` received from the request.
    public let response: URLResponse?

    /// The ``SmartURLSession`` that made the request.
    public let session: SmartURLSession

    /// The ``Error`` that occurred during the request, if any.
    public private(set) var error: Error?

    /// Lazily computed property to extract the URL from an HTTPURLResponse.
    public lazy var url: URL? = (response as? HTTPURLResponse)?.url

    /// Lazily computed property to retrieve all header fields from an HTTPURLResponse.
    public lazy var allHeaderFields: [AnyHashable: Any] = {
        return (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
    }()

    /// Lazily computed property to represent the StatusCode enum of the response.
    public lazy var statusCode: StatusCode? = statusCodeInt.map(StatusCode.init(code:))

    /// Lazily computed property to retrieve the status code as an integer from an HTTPURLResponse.
    public lazy var statusCodeInt: Int? = (response as? HTTPURLResponse)?.statusCode

    /// Lazily computed property to represent the error as a URLError if it exists.
    public lazy var urlError: URLError? = error as? URLError

    /// Creates a new instance of `SmartResponse`.
    ///
    /// - Parameters:
    ///   - request: The original request that initiated the transaction.
    ///   - body: The response body data.
    ///   - response: The `URLResponse` returned from the server.
    ///   - error: Any error encountered during the request.
    ///   - session: The session that executed the request.
    public init(request: URLRequestRepresentation?,
                body: Data?,
                response: URLResponse?,
                error: Error?,
                session: SmartURLSession) {
        self.request = request
        self.body = body
        self.response = response
        self.error = error
        self.session = session
    }

    /// Updates the error property of the SmartResponse object.
    ///
    /// - Parameter error: The error object to set.
    internal func set(error: Error?) {
        self.error = error
    }

    /// Throws an error if the response indicates the request was cancelled.
    ///
    /// This method checks for both `CancellationError` and `URLError.cancelled` cases and throws `CancellationError`
    /// if either is found.
    internal func checkCancellation() throws {
        if let error = error as? CancellationError {
            throw error
        } else if let error = error as? URLError,
                  error.code == .cancelled {
            throw CancellationError()
        }
    }
}

// MARK: - CURLConvertible

extension SmartResponse: CURLConvertible {
    /// Generates a `cURL` command string representing the original request.
    ///
    /// - Parameter prettyPrinted: If `true`, appends `| json_pp` to format JSON output.
    /// - Returns: A string containing the cURL representation of the original request, or a fallback message if not available.
    public func cURLDescription(prettyPrinted: Bool = false) -> String {
        guard let sdk = request?.sdk else {
            return "$ curl command could not be created"
        }
        return cURLDescription(with: session, request: sdk, prettyPrinted: prettyPrinted)
    }
}

#if swift(>=6.0)
extension SmartResponse: @unchecked Sendable {}
#endif
