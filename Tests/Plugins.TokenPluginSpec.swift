import Foundation
import UIKit

import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

class Plugins_TokenPluginSpec: QuickSpec {
    private enum Constant {
        static let sharedName = "Plugins.TokenPlugin"
        static let type = "type"
        static let url = URL.testMake("http://www.dodo.com")
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

            describe(tokenType.name) {
                context("when token is absent") {
                    var subject: Plugins.TokenPlugin!
                    var request: FakeURLRequestable!
                    var parameters: Parameters!

                    beforeEach {
                        request = .init()
                        parameters = .testMake()
                        let authTokenProvider: Plugins.TokenPlugin.TokenProvider = {
                            return nil
                        }

                        subject = .init(type: tokenType, tokenProvider: authTokenProvider)
                        subject.prepare(parameters, request: request)
                    }

                    it("should not modify request") {
                        switch tokenType {
                        case .header(let operation):
                            switch operation {
                            case .add:
                                expect(request).toNot(haveReceived(.addValue))
                            case .set:
                                expect(request).toNot(haveReceived(.setValue))
                            }
                        case .queryParam:
                            expect(request).toNot(haveReceived(.url))
                        }
                    }
                }

                context("when token is absent") {
                    var subject: Plugins.TokenPlugin!
                    var request: FakeURLRequestable!
                    var parameters: Parameters!

                    beforeEach {
                        request = .init()
                        parameters = .testMake()
                        let authTokenProvider: Plugins.TokenPlugin.TokenProvider = {
                            return Constant.value
                        }

                        switch tokenType {
                        case .header(let operation):
                            switch operation {
                            case .add(let key):
                                request.stub(.addValue).with(Constant.value, key).andReturn()
                            case .set(let key):
                                request.stub(.setValue).with(Constant.value, key).andReturn()
                            }
                        case .queryParam:
                            request.stub(.url).andReturn(Constant.url)
                        }

                        subject = .init(type: tokenType, tokenProvider: authTokenProvider)
                        subject.prepare(parameters, request: request)
                    }

                    it("should not modify request") {
                        switch tokenType {
                        case .header(let operation):
                            switch operation {
                            case .add(let key):
                                expect(request).to(haveReceived(.addValue, with: Constant.value, key))
                            case .set(let key):
                                expect(request).to(haveReceived(.setValue, with: Constant.value, key))
                            }
                        case .queryParam(let string):
                            let newUrl = [Constant.url.absoluteString.replacingOccurrences(of: "?my_token_key=broken_token_string",
                                                                                           with: ""), "?", string, "=", Constant.value].joined()
                            expect(request).to(haveReceived(.url, with: URL.testMake(newUrl)))
                        }
                    }
                }
            }
        }

        // MARK: queryParam

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.queryParam(Constant.key)]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.queryParam(Constant.key)]
        }

        // MARK: header.set

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.set(Constant.key))]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.set(Constant.key))]
        }

        // MARK: header.add

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.add(Constant.key))]
        }

        itBehavesLike(Constant.sharedName) {
            return [Constant.type: TokenType.header(.add(Constant.key))]
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
