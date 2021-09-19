import Foundation
import UIKit

import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

class AddressSpec: QuickSpec {
    override func spec() {
        describe("Address") {
            var subject: Address!

            describe("url") {
                context("without scheme") {
                    beforeEach {
                        subject = .url(.testMake("some.com"))
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("some.com")
                    }
                }

                context("https scheme and endpoint") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com/asd"))
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com/asd")
                    }
                }

                context("http scheme") {
                    beforeEach {
                        subject = .url(.testMake("http://some.com"))
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("http://some.com")
                    }
                }

                context("https scheme") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com"))
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com")
                    }
                }
            }

            describe("constructor") {
                context("host") {
                    beforeEach {
                        subject = .address(host: "some.com")
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com")
                    }
                }

                context("unexpected character in the host name") {
                    beforeEach {
                        subject = .address(host: "\"some.com")
                    }

                    it("should throw error") {
                        expect({ try subject.url() }) == .testMake("https://%22some.com")
                    }
                }

                context("host; endpoint") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint")
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com/endpoint")
                    }
                }

                context("host; endpoint with slashes") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "/endpoint/")
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com/endpoint")
                    }
                }

                context("host; endpoint; queryItems") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com/endpoint?item=value")
                    }
                }

                context("host; endpoint with slashes; queryItems") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com/endpoint?item=value")
                    }
                }

                context("host qith query items; endpoint with slashes; queryItems with broken format") {
                    beforeEach {
                        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect({ try subject.url() }) == .testMake("https://some.com%2Fitem=value/endpoint?item=value")
                    }
                }
            }
        }
    }
}
