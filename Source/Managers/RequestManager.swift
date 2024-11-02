import Foundation
import Threading

#if swift(>=6.0)
/// A protocol that represents a ``SmartRequestManager`` interface which can be used to mock requests in unit tests.
public protocol RequestManager: Sendable {
    /// A closure that is called when a response is received.
    typealias ResponseClosure = (_ result: RequestResult) -> Void

    /// Sends a request to the specified address with the given parameters.
    func request(address: Address,
                 parameters: Parameters,
                 completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking
}
#else
/// A protocol that represents a request manager interface which can be used to mock requests in unit tests.
public protocol RequestManager {
    /// A closure that is called when a response is received.
    typealias ResponseClosure = (_ result: RequestResult) -> Void

    /// Sends a request to the specified address with the given parameters.
    func request(address: Address,
                 parameters: Parameters,
                 completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking
}
#endif

public extension RequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request(address: Address, parameters: Parameters = .init()) -> AnyRequest {
        return .init(pure: self, address: address, parameters: parameters)
    }

    /// Sends a request to the specified address with the given parameters.
    func request(address: Address, parameters: Parameters = .init()) async -> RequestResult {
        return await withCheckedContinuation { [self] continuation in
            request(address: address, parameters: parameters, completionQueue: .absent) { result in
                continuation.resume(returning: result)
            }
            .detach().deferredStart()
        }
    }
}

public extension RequestManager {
    /// ``Void`` request manager.
    var void: TypedRequestManager<Void> {
        return .init(VoidContent(), parent: self)
    }

    /// ``Decodable`` request manager.
    var decodable: DecodableRequestManager {
        return .init(parent: self)
    }

    // MARK: - strong

    /// ``Data`` request manager.
    var data: TypedRequestManager<Data> {
        return custom(DataContent())
    }

    /// ``Image`` request manager.
    var image: TypedRequestManager<Image> {
        return custom(ImageContent())
    }

    /// ``JSON`` request manager.
    var json: TypedRequestManager<Any> {
        return custom(JSONContent())
    }

    // MARK: - optional

    /// ``Data`` request manager.
    var dataOptional: TypedRequestManager<Data?> {
        return customOptional(DataContent())
    }

    /// ``Image`` request manager.
    var imageOptional: TypedRequestManager<Image?> {
        return customOptional(ImageContent())
    }

    /// ``JSON`` request manager.
    var jsonOptional: TypedRequestManager<Any?> {
        return customOptional(JSONContent())
    }

    // MARK: - custom

    /// Custom request manager which can be used to create a request manager with a custom ``Deserializable`` of your own choice.
    func custom<T: Deserializable>(_ decoder: T) -> TypedRequestManager<T.Object> {
        return .init(decoder, parent: self)
    }

    /// Custom request manager which can be used to create a request manager with a custom ``Deserializable`` of your own choice.
    func customOptional<T: Deserializable>(_ type: T) -> TypedRequestManager<T.Object?> {
        return .init(type, parent: self)
    }
}
