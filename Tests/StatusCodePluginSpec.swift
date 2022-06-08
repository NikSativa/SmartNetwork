import Foundation
import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class StatusCodePluginSpec: QuickSpec {
    override func spec() {
        describe("StatusCodePlugin") {
            var subject: Plugins.StatusCode!

            beforeEach {
                subject = .init()
            }

            context("when status code is absent") {
                it("should pass") {
                    expect({ try subject.verify(data: .testMake()) }).toNot(throwError())
                }
            }

            context("when receiving status code 200") {
                it("should pass") {
                    expect({ try subject.verify(data: .testMake(statusCode: 200)) }).toNot(throwError())
                }
            }

            context("when receiving status code 0..<1000") {
                it("should throw corresponding error") {
                    let codes: [Int: StatusCode] = [
                        201: .created,
                        202: .accepted,
                        203: .nonAuthoritativeInformation,
                        204: .noContent,
                        205: .resetContent,
                        206: .partialContent,
                        207: .multiStatus,
                        208: .alreadyReported,
                        226: .imUsed,
                        300: .multipleChoises,
                        301: .movedPermanently,
                        302: .found,
                        303: .seeOther,
                        304: .notModified,
                        307: .temporaryRedirect,
                        308: .permanentRedirect,
                        400: .badRequest,
                        401: .unauthorized,
                        403: .forbidden,
                        404: .notFound,
                        405: .methodNotAllowed,
                        406: .notAcceptable,
                        407: .proxyAuthenticationRequiered
                        408: .timeout
                        409: .conflict
                        410: .gone
                        411: .lenghtRequired
                        412: .preconditionFailed
                        413: .payloadTooLarge
                        414: .uriTooLong
                        415: .unsupportedMediaType
                        416: .rangeNotSatisfiable
                        417: .expectationFailed
                        418: .teapot
                        422: .unprocessableEntity
                        426: .upgradeRequired,
                        428: .preconditionFailed
                        429: .tooManyRequests,
                        431: .headersTooLarge
                        451: .unavailableForLegalReasons
                        500: .serverError
                        501: .notImplemented
                        502: .badGateway
                        503: .serviceUnavailable
                        504: .gatewayTimeout
                        505: .httpVersionNotSupported
                        506: .variantAlsoNegotiates
                        507: .insufficiantStorage
                        508: .loopDetected
                        510: .notExtended
                        511: .networkAuthenticationRequired
                    ]

                    for code in 0..<1000 where code != 200 {
                        let error = codes[code] ?? .other(code)
                        expect({ try subject.verify(data: .testMake(statusCode: code)) }).to(throwError(error))
                    }
                }
            }
        }
    }
}
