import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class Plugins_TokenPluginSpec: QuickSpec {
    private enum Constant {
        static let sharedName = "Plugins.TokenPlugin"
        static let type = "type"
        static let originalURLRequest = "originalURLRequest"
        static let expectedURLRequest = "expectedURLRequest"
        static let sufixKey = "sufix"
        static let sufixValue = "; when original request already has parameter"
        static let url = "http://www.dodo.com"
        static let value = "my_token_string"
        static let key = "my_token_key"
    }

    private typealias TokenType = Plugins.TokenType

    override func spec() {
        sharedExamples(Constant.sharedName) { contextInfo in
            let contextInfo = contextInfo()

            guard let tokenType = contextInfo[Constant.type] as? TokenType else {
                fail("\(type(of: self)) lacks parameter '\(Constant.type)'")
                return
            }

            guard let originalURLRequest = contextInfo[Constant.originalURLRequest] as? URLRequest else {
                fail("\(type(of: self)) lacks parameter '\(Constant.originalURLRequest)'")
                return
            }

            guard let expectedURLRequest = contextInfo[Constant.expectedURLRequest] as? URLRequest else {
                fail("\(type(of: self)) lacks parameter '\(Constant.expectedURLRequest)'")
                return
            }

            let sufix = contextInfo[Constant.sufixKey] as? String

            describe(tokenType.name + (sufix ?? "")) {
                context("when token is absent") {
                    var subject: Plugins.TokenPlugin!
                    var info: RequestInfo!

                    beforeEach {
                        let authTokenProvider: Plugins.TokenPlugin.TokenProviderClosure = {
                            return nil
                        }

                        subject = .init(type: tokenType, tokenProvider: authTokenProvider)

                        info = RequestInfo.testMake(request: originalURLRequest)
                        subject.prepare(&info)
                    }

                    it("should not modify request") {
                        expect(info.request) == originalURLRequest 
                    }
                }

                context("when token has been provided") {
                    var subject: Plugins.TokenPlugin!
                    var authTokenProvider: Plugins.TokenPlugin.TokenProviderClosure!

                    beforeEach {
                        authTokenProvider = {
                            return Constant.value
                        }

                        subject = .init(type: tokenType, tokenProvider: authTokenProvider)
                    }

                    it("should not verify anything") {
                        expect({ try subject.verify(httpStatusCode: 123, header: [:], data: nil, error: nil) }).toNot(throwError())
                    }

                    describe("prepare") {
                        var info: RequestInfo!

                        beforeEach {
                            info = .testMake(request: originalURLRequest)
                            subject.prepare(&info)
                        }

                        it("should modify request") {
                            expect(info.request) != originalURLRequest
                            expect(info.request) == expectedURLRequest
                        }
                    }
                }
            }
        }

        // MARK: queryParam
        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.queryParam(Constant.key),
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url)),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url + "?my_token_key=my_token_string"))]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.queryParam(Constant.key),
                    Constant.sufixKey: Constant.sufixValue,
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url + "?my_token_key=my_token_string_original")),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url + "?my_token_key=my_token_string"))]
        }

        // MARK: header.set
        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.set(Constant.key)),
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url)),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value])]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.set(Constant.key)),
                    Constant.sufixKey: Constant.sufixValue,
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value + "_original"]),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value])]
        }

        // MARK: header.add
        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.add(Constant.key)),
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url)),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value])]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.add(Constant.key)),
                    Constant.sufixKey: Constant.sufixValue,
                    Constant.originalURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value + "_original"]),
                    Constant.expectedURLRequest: URLRequest.testMake(url: .testMake(Constant.url),
                                                                     headers: [Constant.key: Constant.value + "_original" + "," + Constant.value])]
        }
    }
}

private extension Plugins.TokenType {
    var name: String {
        switch self {
        case .queryParam:
            return "queryParam"
        case .header(let operation):
            switch operation {
            case .set:
                return "header.set"
            case .add:
                return "header.add"
            }
        }
    }
}
