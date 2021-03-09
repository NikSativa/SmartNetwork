import Foundation
import Quick
import Nimble
import Spry_Nimble

@testable import NRequest
#if canImport(NRequest_Inject)
@testable import NRequest_Inject
#endif
@testable import NRequestTestHelpers
@testable import NInject
@testable import NInjectTestHelpers

class RequestAssemblySpec: QuickSpec {
    override func spec() {
        describe("RequestAssembly") {
            var subject: RequestAssembly!
            var registrator: TestContainer!
            var container: Container!

            beforeEach {
                subject = .init()
                registrator = .init(assemblies: [subject])
                container = .init(assemblies: [subject])
                container.register(BearerTokenProvider.self, FakeBearerTokenProvider.init)
            }

            it("should resolve dependencies") {
                let expected: [RegistrationInfo] = [.register(AnyRequestFactory<RequestError>.self, .container + .open),
                                                    .register(Plugins.StatusCode.self, .transient),
                                                    .register(Plugins.Bearer.self, .transient)]
                expect(registrator.registered) == expected
            }

            it("should create AnyRequestFactory") {
                let value = container.optionalResolve(AnyRequestFactory<RequestError>.self)
                expect(value).toNot(beNil())
            }

            it("should create Plugins.StatusCode") {
                let value = container.optionalResolve(Plugins.StatusCode.self)
                expect(value).toNot(beNil())
            }
        }
    }
}
