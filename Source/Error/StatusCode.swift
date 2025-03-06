import Foundation

/// The StatusCode struct is designed to represent different status codes and their corresponding kinds,
/// providing flexibility in error handling and status code representations within the system.
public struct StatusCode: Error, Hashable, ExpressibleByIntegerLiteral, SmartSendable {
    public let code: Int
    public let kind: Kind?

    public init(code: Int) {
        self.code = code
        self.kind = Kind(rawValue: code)
    }

    public init(_ kind: Kind) {
        self.code = kind.rawValue
        self.kind = kind
    }

    public init(integerLiteral value: Int) {
        self.init(code: value)
    }
}

public extension StatusCode {
    static var noContent: Self {
        return .init(.noContent)
    }

    static var none: Self {
        return .init(code: -1)
    }
}

// MARK: - RequestErrorDescription

extension StatusCode: RequestErrorDescription {
    public var subname: String {
        return (kind?.name ?? "unknown") + "(\(code))"
    }
}

// MARK: - StatusCode.Kind

public extension StatusCode {
    /// This enum is designed to categorize status codes into different kinds,
    /// facilitating error handling and status code interpretation within the system.
    enum Kind: Int, Hashable, CaseIterable, SmartSendable {
        // MARK: - Successful responses

        case created = 201
        case accepted = 202
        case nonAuthoritativeInformation = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207
        case alreadyReported = 208
        case imUsed = 226

        // MARK: - Redirection messages

        case multipleChoises = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case temporaryRedirect = 307
        case permanentRedirect = 308

        // MARK: - Client error responses

        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthenticationRequiered = 407
        case timeout = 408
        case conflict = 409
        case gone = 410
        case lenghtRequired = 411
        case preconditionFailed = 412
        case payloadTooLarge = 413
        case uriTooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case teapot = 418
        case unprocessableEntity = 422
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case headersTooLarge = 431
        case unavailableForLegalReasons = 451

        // MARK: - Server error responses

        case serverError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case httpVersionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficiantStorage = 507
        case loopDetected = 508
        case notExtended = 510
        case networkAuthenticationRequired = 511
    }
}

public extension StatusCode.Kind {
    var name: String {
        let name: String? = String(reflecting: self).components(separatedBy: ".").last
        return name.unsafelyUnwrapped
    }
}
