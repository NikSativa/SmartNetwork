import Foundation

/// A class representing the result of a network request.
public final class RequestResult {
    /// The original URLRequest made for the request.
    public let request: URLRequestRepresentation?

    /// The body data of the response.
    public let body: Data?

    /// The URLResponse received from the request.
    public let response: URLResponse?

    /// The error that occurred during the request, if any.
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

    /// Initializes a RequestResult object with the provided parameters.
    ///
    /// - Parameters:
    /// - request: The URLRequest made for the request.
    /// - body: The body data of the response.
    /// - response: The URLResponse received.
    /// - error: Any error that occurred during the request.
    init(request: URLRequestRepresentation?,
         body: Data?,
         response: URLResponse?,
         error: Error?) {
        self.request = request
        self.body = body
        self.response = response
        self.error = error
    }

    /// Updates the error property of the RequestResult object.
    ///
    /// - Parameter error: The error object to set.
    func set(_ error: Error?) {
        self.error = error
    }
}

#if swift(>=6.0)
extension RequestResult: @unchecked Sendable {}
#endif
