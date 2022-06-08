import Foundation

public enum StatusCode: Error, Equatable {
    // MARK: - Successful responses
    
    /// 201
    case created
    
    /// 202
    case accepted
    
    /// 203
    case nonAuthoritativeInformation
    
    /// 204
    case noContent
    
    /// 205
    case resetContent
    
    /// 206
    case partialContent
    
    /// 207
    case multiStatus
    
    /// 208
    case alreadyReported
    
    /// 226
    case imUsed
    
    // MARK: - Redirection messages
    
    /// 300
    case multipleChoises
    
    /// 301
    case movedPermanently
    
    /// 302
    case found
    
    /// 303
    case seeOther
    
    /// 304
    case notModified
    
    /// 307
    case temporaryRedirect
    
    /// 308
    case permanentRedirect
    
    // MARK: - Client error responses
    
    /// 400
    case badRequest
    
    /// 401
    case unauthorized
    
    /// 403
    case forbidden
    
    /// 404
    case notFound
    
    /// 405
    case methodNotAllowed
    
    /// 406
    case notAcceptable
    
    /// 407
    case proxyAuthenticationRequiered
    
    /// 408
    case timeout
    
    /// 409
    case conflict
    
    /// 410
    case gone
    
    /// 411
    case lenghtRequired
    
    /// 412
    case preconditionFailed
    
    /// 413
    case payloadTooLarge
    
    /// 414
    case uriTooLong
    
    /// 415
    case unsupportedMediaType
    
    /// 416
    case rangeNotSatisfiable
    
    /// 417
    case expectationFailed
    
    /// 418
    case teapot
    
    /// 422
    case unprocessableEntity
    
    /// 426
    case upgradeRequired
    
    /// 428
    case preconditionFailed
    
    /// 429
    case tooManyRequests
    
    /// 431
    case headersTooLarge
    
    /// 451
    case unavailableForLegalReasons
    
    // MARK: - Server error responses
    
    /// 500
    case serverError
    
    /// 501
    case notImplemented
    
    /// 502
    case badGateway
    
    /// 503
    case serviceUnavailable
    
    /// 504
    case gatewayTimeout
    
    /// 505
    case httpVersionNotSupported
    
    /// 506
    case variantAlsoNegotiates
    
    /// 507
    case insufficiantStorage
    
    /// 508
    case loopDetected
    
    /// 510
    case notExtended
    
    /// 511
    case networkAuthenticationRequired
    
    /// other errors unsupported by StatusCode
    case other(Int)
}

public extension StatusCode {
    func toInt() -> Int {
        switch self {
        case .created:
            return 201
        case .accepted:
            return 202
        case .nonAuthoritativeInformation:
            return 203
        case .noContent:
            return 204
        case .resetContent:
            return 205
        case .partialContent:
            return 206
        case .multiStatus:
            return 207
        case .alreadyReported:
            return 208
        case .imUsed:
            return 226
        case .multipleChoises:
            return 300
        case .movedPermanently:
            return 301
        case .found:
            return 302
        case .seeOther:
            return 303
        case .notModified:
            return 304
        case .temporaryRedirect:
            return 307
        case .permanentRedirect:
            return 308
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .methodNotAllowed:
            return 405
        case .notAcceptable:
            return 406
        case .proxyAuthenticationRequiered:
            return 407
        case .timeout:
            return 408
        case .conflict:
            return 409
        case .gone:
            return 410
        case .lenghtRequired:
            return 411
        case .preconditionFailed:
            return 412
        case .payloadTooLarge:
            return 413
        case .uriTooLong:
            return 414
        case .unsupportedMediaType:
            return 415
        case .rangeNotSatisfiable:
            return 416
        case .expectationFailed:
            return 417
        case .teapot:
            return 418
        case .unprocessableEntity:
            return 422
        case .upgradeRequired:
            return 426
        case .preconditionFailed:
            return 428
        case .tooManyRequests:
            return 429
        case .headersTooLarge:
            return 431
        case .unavailableForLegalReasons:
            return 451
        case .serverError:
            return 500
        case .notImplemented:
            return 501
        case .badGateway:
            return 502
        case .serviceUnavailable:
            return 503
        case .gatewayTimeout:
            return 504
        case .httpVersionNotSupported:
            return 505
        case .variantAlsoNegotiates:
            return 506
        case .insufficiantStorage:
            return 507
        case .loopDetected:
            return 508
        case .notExtended:
            return 510
        case .networkAuthenticationRequired:
            return 511
        case .other(let code):
            return code
        }
    }
}

public extension StatusCode {
    init?(_ code: Int?) {
        guard let code = code else {
            return nil
        }

        switch code {
        case 200:
            return nil
        case 201:
            self = .created
        case 202:
            self = .accepted
        case 203:
            self = .nonAuthoritativeInformation
        case 204:
            self = .noContent
        case 205:
            self = .resetContent
        case 206:
            self = .partialContent
        case 207:
            self = .multiStatus
        case 208:
            self = .alreadyReported
        case 226:
            self = .imUsed
        case 300:
            self = .multipleChoises
        case 301:
            self = .movedPermanently
        case 302:
            self = .found
        case 303:
            self = .seeOther
        case 304:
            self = .notModified
        case 307:
            self = .temporaryRedirect
        case 308:
            self = .permanentRedirect
        case 400:
            self = .badRequest
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 405:
            self = .methodNotAllowed
        case 406:
            self = .notAcceptable
        case 407:
            self = .proxyAuthenticationRequiered
        case 408:
            self = .timeout
        case 409:
            self = .conflict
        case 410:
            self = .gone
        case 411:
            self = .lenghtRequired
        case 412:
            self = .preconditionFailed
        case 413:
            self = .payloadTooLarge
        case 414:
            self = .uriTooLong
        case 415:
            self = .unsupportedMediaType
        case 416:
            self = .rangeNotSatisfiable
        case 417:
            self = .expectationFailed
        case 418:
            self = .teapot
        case 422:
            self = .unprocessableEntity
        case 426:
            self = .upgradeRequired
        case 428:
            self = .preconditionFailed
        case 429:
            self = .tooManyRequests
        case 431:
            self = .headersTooLarge
        case 451:
            self = .unavailableForLegalReasons
        case 500:
            self = .serverError
        case 501:
            self = .notImplemented
        case 502:
            self = .badGateway
        case 503:
            self = .serviceUnavailable
        case 504:
            self = .gatewayTimeout
        case 505:
            self = .httpVersionNotSupported
        case 506:
            self = .variantAlsoNegotiates
        case 507:
            self = .insufficiantStorage
        case 508:
            self = .loopDetected
        case 510:
            self = .networkAuthenticationRequired
        default:
            self = .other(code)
        }
    }
}
