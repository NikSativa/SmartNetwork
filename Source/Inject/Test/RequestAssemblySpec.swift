import Quick
import Nimble
import Spry_Nimble

@testable import NRequest
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
                container.register(AuthTokenProvider.self, FakeAuthTokenProvider.init)
            }

            it("should resolve dependencies") {
                let expected: [RegistrationInfo] = [.register(AnyRequestFactory<RequestError>.self, .transient),
                                                    .register(BaseRequestFactory<RequestError>.self, .transient),
                                                    .register(Plugins.StatusCode.self, .transient),
                                                    .register(Plugins.Bearer.Provider.self, .transient),
                                                    .register(Plugins.Bearer.Storage.self, .transient),
                                                    .register(UserDefaults.self, .container + .open),
                                                    .register(Storages.UserDefaults.self, .transient + .open),
                                                    .register(Storages.Keyed<String>.self, .container + .open),
                                                    .register(AnyStorage<String, String>.self, .transient + .open),]
                expect(registrator.registered).to(equal(expected))
            }

            it("should create AnyRequestFactory") {
                let value = container.optionalResolve(AnyRequestFactory<RequestError>.self)
                expect(value).toNot(beNil())
            }

            it("should create BaseRequestFactory") {
                let value = container.optionalResolve(BaseRequestFactory<RequestError>.self)
                expect(value).toNot(beNil())
            }

            it("should create Plugins.StatusCode") {
                let value = container.optionalResolve(Plugins.StatusCode.self)
                expect(value).toNot(beNil())
            }

            it("should create Plugins.Bearer.Provider") {
                let value = container.optionalResolve(Plugins.Bearer.Provider.self)
                expect(value).toNot(beNil())
            }

            it("should create Plugins.Bearer.Storage") {
                let value = container.optionalResolve(Plugins.Bearer.Storage.self, with: ["key"])
                expect(value).toNot(beNil())
            }

            it("should create KeyedStorage") {
                let value = container.optionalResolve(Storages.Keyed<String>.self, with: ["key"])
                expect(value).toNot(beNil())
            }
        }
    }
}
