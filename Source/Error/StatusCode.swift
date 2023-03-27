import Foundation

public struct StatusCode: Error, Hashable {
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
}

// MARK: - StatusCode.Kind

public extension StatusCode {
    enum Kind: Int, Hashable, CaseIterable {
        // MARK: - Successful responses

        case success = 200
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

public extension StatusCode {
    var isSuccess: Bool {
        return kind?.isSuccess == true
    }

    static var noContent: Self {
        return .init(.noContent)
    }
}

public extension StatusCode.Kind {
    var isSuccess: Bool {
        switch self {
        case .accepted,
             .alreadyReported,
             .created,
             .imUsed,
             .multiStatus,
             .noContent,
             .nonAuthoritativeInformation,
             .partialContent,
             .resetContent,
             .success:
            return true
        case .badGateway,
             .badRequest,
             .conflict,
             .expectationFailed,
             .forbidden,
             .found,
             .gatewayTimeout,
             .gone,
             .headersTooLarge,
             .httpVersionNotSupported,
             .insufficiantStorage,
             .lenghtRequired,
             .loopDetected,
             .methodNotAllowed,
             .movedPermanently,
             .multipleChoises,
             .networkAuthenticationRequired,
             .notAcceptable,
             .notExtended,
             .notFound,
             .notImplemented,
             .notModified,
             .payloadTooLarge,
             .permanentRedirect,
             .preconditionFailed,
             .preconditionRequired,
             .proxyAuthenticationRequiered,
             .rangeNotSatisfiable,
             .seeOther,
             .serverError,
             .serviceUnavailable,
             .teapot,
             .temporaryRedirect,
             .timeout,
             .tooManyRequests,
             .unauthorized,
             .unavailableForLegalReasons,
             .unprocessableEntity,
             .unsupportedMediaType,
             .upgradeRequired,
             .uriTooLong,
             .variantAlsoNegotiates:
            return false
        }
    }

    var name: String {
        let name: String? = String(reflecting: self).components(separatedBy: ".").last
        return name ?? "!unknown name!"
    }
}

// MARK: - StatusCode + CustomDebugStringConvertible, CustomStringConvertible

extension StatusCode: CustomDebugStringConvertible, CustomStringConvertible {
    private func makeDescription() -> String {
        let name = (kind?.name).map {
            return " (\($0))"
        }
        return "StatusCode \(code)" + (name ?? "")
    }

    public var debugDescription: String {
        return makeDescription()
    }

    public var description: String {
        return makeDescription()
    }
}
