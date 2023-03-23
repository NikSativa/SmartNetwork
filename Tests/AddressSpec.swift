import Foundation
import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class AddressSpec: QuickSpec {
    override func spec() {
        describe("Address") {
            var subject: Address!

            describe("url") {
                context("without scheme") {
                    beforeEach {
                        subject = .url(.testMake("some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("some.com")
                    }
                }

                context("without scheme; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .url(.testMake("some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("some.com")
                    }
                }

                context("https scheme and endpoint") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com/asd"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com/asd")
                    }
                }

                context("https scheme and endpoint; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com/asd"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com/asd")
                    }
                }

                context("http scheme") {
                    beforeEach {
                        subject = .url(.testMake("http://some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("http://some.com")
                    }
                }

                context("http scheme; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .url(.testMake("http://some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("http://some.com")
                    }
                }

                context("https scheme") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com")
                    }
                }

                context("https scheme; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .url(.testMake("https://some.com"))
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com")
                    }
                }
            }

            describe("constructor") {
                context("host") {
                    beforeEach {
                        subject = .address(host: "some.com")
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com")
                    }
                }

                context("host; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "some.com")
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com")
                    }
                }

                context("unexpected character in the host name; shouldAddSlashAfterEndpoint: true") {
                    beforeEach {
                        subject = .address(host: "\"some.com")
                    }

                    #if os(macOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://%22some.com")
                    }
                    #endif

                    #if os(iOS)
                    it("should throw error") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        }.to(throwError(EncodingError.lackAdress))
                    }
                    #endif
                }

                context("unexpected character in the host name; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "\"some.com")
                    }

                    #if os(macOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://%22some.com")
                    }
                    #endif

                    #if os(iOS)
                    it("should throw error") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        }.to(throwError(EncodingError.lackAdress))
                    }
                    #endif
                }

                context("host; endpoint") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint")
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com/endpoint")
                    }
                }

                context("host; endpoint; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint")
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com/endpoint")
                    }
                }

                context("host; endpoint with slashes") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "/endpoint/")
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com/endpoint")
                    }
                }

                context("host; endpoint; queryItems; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com/endpoint?item=value")
                    }
                }

                context("host; endpoint; queryItems") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com/endpoint/?item=value")
                    }
                }

                context("host; endpoint with slashes; queryItems") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com/endpoint/?item=value")
                    }
                }

                context("host; endpoint with slashes; queryItems; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
                    }

                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com/endpoint?item=value")
                    }
                }

                context("host qith query items; endpoint with slashes; queryItems with broken format; shouldAddSlashAfterEndpoint: true") {
                    beforeEach {
                        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
                    }
                    #if os(macOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        } == .testMake("https://some.com%2Fitem=value/endpoint/?item=value")
                    }
                    #endif

                    #if os(iOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: true)
                        }.to(throwError(EncodingError.lackAdress))
                    }
                    #endif
                }

                context("host qith query items; endpoint with slashes; queryItems with broken format; shouldAddSlashAfterEndpoint: false") {
                    beforeEach {
                        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
                    }

                    #if os(macOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        } == .testMake("https://some.com%2Fitem=value/endpoint?item=value")
                    }
                    #endif

                    #if os(iOS)
                    it("should pass the url") {
                        expect {
                            try subject.url(shouldAddSlashAfterEndpoint: false)
                        }.to(throwError(EncodingError.lackAdress))
                    }
                    #endif
                }
            }
        }
    }
}
