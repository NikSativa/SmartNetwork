import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class AddressSpec: QuickSpec {
    override func spec() {
        fdescribe("Address") {
            var subject: Address!

            describe("url") {
                context("without scheme") {
                    beforeEach {
                        subject = .url(.testMake("some.com"))
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com")))
                    }
                }

                context("http scheme") {
                    beforeEach {
                        subject = .url(.testMake("http://some.com"))
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com")))
                    }
                }

                context("https scheme") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com"))
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com")))
                    }
                }
            }

            describe("constructor") {
                context("host") {
                    beforeEach {
                        subject = .init(host: "some.com")
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com")))
                    }
                }

                context("broken host") {
                    beforeEach {
                        subject = .init(host: "\"some.com")
                    }

                    it("should throw error") {
                        expect(expression: { try subject.url() }).to(throwError(EncodingError.lackAdress))
                    }
                }

                context("host; endpoint") {
                    beforeEach {
                        subject = .init(host: "some.com", endpoint: "endpoint")
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com/endpoint")))
                    }
                }

                context("host; endpoint with slashes") {
                    beforeEach {
                        subject = .init(host: "some.com", endpoint: "/endpoint/")
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com/endpoint/")))
                    }
                }

                context("host; endpoint; queryItems") {
                    beforeEach {
                        subject = .init(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com/endpoint?item=value")))
                    }
                }

                context("host; endpoint with slashes; queryItems") {
                    beforeEach {
                        subject = .init(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com/endpoint?item=value")))
                    }
                }

                context("host qith query items; endpoint with slashes; queryItems with broken format") {
                    beforeEach {
                        subject = .init(host: "some.com?item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect(expression: { try subject.url() }).to(equal(.testMake("some.com/endpoint/?item=value")))
                    }
                }
            }
        }
    }
}
