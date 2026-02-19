import Foundation

/// Represents an HTTP status code with optional semantic categorization via `Kind`.
///
/// Encapsulates both the numeric code and, where applicable, a strongly typed `Kind` value that gives
/// semantic meaning to the code. This is useful for matching, debugging, and analytics in HTTP workflows.
public struct StatusCode: Error, Hashable, ExpressibleByIntegerLiteral, SmartSendable {
    /// The numeric HTTP status code (for example, `200` or `404`).
    public let code: Int
    /// Semantic representation of `code` when it matches a known ``StatusCode/Kind``.
    public let kind: Kind?

    /// Creates a status code from a numeric value.
    ///
    /// - Parameter code: Numeric HTTP status code.
    public init(code: Int) {
        self.code = code
        self.kind = Kind(rawValue: code)
    }

    /// Creates a status code from a semantic ``StatusCode/Kind``.
    ///
    /// - Parameter kind: Semantic status code kind.
    public init(_ kind: Kind) {
        self.code = kind.rawValue
        self.kind = kind
    }

    public init(integerLiteral value: Int) {
        self.init(code: value)
    }
}

public extension StatusCode {
    /// Convenience value for HTTP 204 (`noContent`).
    static var noContent: Self {
        return .init(.noContent)
    }

    /// Sentinel value for an unknown or missing status (`-1`).
    static var none: Self {
        return .init(code: -1)
    }
}

// MARK: - RequestErrorDescription

extension StatusCode: RequestErrorDescription {
    /// A human-readable label combining the semantic kind and numeric code.
    ///
    /// Example: `"notFound(404)"`. Useful for error logging or diagnostics.
    public var subname: String {
        return (kind?.name ?? "unknown") + "(\(code))"
    }
}

// MARK: - StatusCode.Kind

public extension StatusCode {
    /// Defines semantic names for well-known HTTP status codes.
    ///
    /// This provides clarity when comparing or categorizing HTTP status codes programmatically.
    enum Kind: Int, Hashable, CaseIterable, SmartSendable {
        // MARK: - Successful responses

        /// HTTP 201 Created.
        case created = 201
        /// HTTP 202 Accepted.
        case accepted = 202
        /// HTTP 203 Non-Authoritative Information.
        case nonAuthoritativeInformation = 203
        /// HTTP 204 No Content.
        case noContent = 204
        /// HTTP 205 Reset Content.
        case resetContent = 205
        /// HTTP 206 Partial Content.
        case partialContent = 206
        /// HTTP 207 Multi-Status.
        case multiStatus = 207
        /// HTTP 208 Already Reported.
        case alreadyReported = 208
        /// HTTP 226 IM Used.
        case imUsed = 226

        // MARK: - Redirection messages

        /// HTTP 300 Multiple Choices.
        case multipleChoices = 300
        /// HTTP 301 Moved Permanently.
        case movedPermanently = 301
        /// HTTP 302 Found.
        case found = 302
        /// HTTP 303 See Other.
        case seeOther = 303
        /// HTTP 304 Not Modified.
        case notModified = 304
        /// HTTP 307 Temporary Redirect.
        case temporaryRedirect = 307
        /// HTTP 308 Permanent Redirect.
        case permanentRedirect = 308

        // MARK: - Client error responses

        /// HTTP 400 Bad Request.
        case badRequest = 400
        /// HTTP 401 Unauthorized.
        case unauthorized = 401
        /// HTTP 403 Forbidden.
        case forbidden = 403
        /// HTTP 404 Not Found.
        case notFound = 404
        /// HTTP 405 Method Not Allowed.
        case methodNotAllowed = 405
        /// HTTP 406 Not Acceptable.
        case notAcceptable = 406
        /// HTTP 407 Proxy Authentication Required.
        case proxyAuthenticationRequired = 407
        /// HTTP 408 Request Timeout.
        case timeout = 408
        /// HTTP 409 Conflict.
        case conflict = 409
        /// HTTP 410 Gone.
        case gone = 410
        /// HTTP 411 Length Required.
        case lengthRequired = 411
        /// HTTP 412 Precondition Failed.
        case preconditionFailed = 412
        /// HTTP 413 Payload Too Large.
        case payloadTooLarge = 413
        /// HTTP 414 URI Too Long.
        case uriTooLong = 414
        /// HTTP 415 Unsupported Media Type.
        case unsupportedMediaType = 415
        /// HTTP 416 Range Not Satisfiable.
        case rangeNotSatisfiable = 416
        /// HTTP 417 Expectation Failed.
        case expectationFailed = 417
        /// HTTP 418 I'm a teapot.
        case teapot = 418
        /// HTTP 422 Unprocessable Entity.
        case unprocessableEntity = 422
        /// HTTP 426 Upgrade Required.
        case upgradeRequired = 426
        /// HTTP 428 Precondition Required.
        case preconditionRequired = 428
        /// HTTP 429 Too Many Requests.
        case tooManyRequests = 429
        /// HTTP 431 Request Header Fields Too Large.
        case headersTooLarge = 431
        /// HTTP 451 Unavailable For Legal Reasons.
        case unavailableForLegalReasons = 451

        // MARK: - Server error responses

        /// HTTP 500 Internal Server Error.
        case serverError = 500
        /// HTTP 501 Not Implemented.
        case notImplemented = 501
        /// HTTP 502 Bad Gateway.
        case badGateway = 502
        /// HTTP 503 Service Unavailable.
        case serviceUnavailable = 503
        /// HTTP 504 Gateway Timeout.
        case gatewayTimeout = 504
        /// HTTP 505 HTTP Version Not Supported.
        case httpVersionNotSupported = 505
        /// HTTP 506 Variant Also Negotiates.
        case variantAlsoNegotiates = 506
        /// HTTP 507 Insufficient Storage.
        case insufficientStorage = 507
        /// HTTP 508 Loop Detected.
        case loopDetected = 508
        /// HTTP 510 Not Extended.
        case notExtended = 510
        /// HTTP 511 Network Authentication Required.
        case networkAuthenticationRequired = 511
    }
}

public extension StatusCode.Kind {
    /// Returns the name of the enum case as a string, suitable for logging or display.
    var name: String {
        let name: String? = String(reflecting: self).components(separatedBy: ".").last
        return name.unsafelyUnwrapped
    }
}
