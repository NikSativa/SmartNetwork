import Foundation
import Swinject
import NRequest

public class RequestAssembly: Assembly {
    public init() { }

    public func assemble(container: Container) {
        container.register(RequestFactory.self) { _ in
            return RequestFactory()
        }
    }
}
