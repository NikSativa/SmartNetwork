import Foundation
import Threading

/// The ``RequestManager`` protocol defines mechanisms for sending requests
/// and includes functions that handle the transmission of requests to specified addresses
/// with specified parameters and with support for custom completion handling in specified queues.
public protocol RequestManager: SmartSendable {
    /// A closure that gets called upon receiving a response.
    typealias ResponseClosure = (_ result: SmartResponse) -> Void

    /// Sends a request asynchronously to the specified address with the given parameters.
    ///
    /// - Parameter address: An ``Address`` object specifying the target address.
    /// - Parameter parameters: A ``Parameters`` object containing the request parameters.
    /// - Parameter userInfo: A ``UserInfo`` object with additional user information.
    func request(address: Address, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse

    /// Sends a request to the specified address with the given parameters.
    ///
    /// - Parameter address: An ``Address`` object specifying the target address.
    /// - Parameter parameters: A ``Parameters`` object containing the request parameters.
    /// - Parameter userInfo: A ``UserInfo`` object with additional user information.
    /// - Parameter completionQueue: A ``DelayedQueue`` where the completion handler will be executed.
    /// - Parameter completion: A ``ResponseClosure`` that is executed when a response is received.
    func request(address: Address, parameters: Parameters, userInfo: UserInfo, completionQueue: DelayedQueue, completion: @escaping ResponseClosure) -> SmartTasking
}

public extension RequestManager {
    /// Sends a request to the specified address with the given parameters.
    func request(address: Address, parameters: Parameters = .init(), userInfo: UserInfo = .init()) -> AnyRequest {
        return .init(pure: self, address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Sends a request to the specified address with the given parameters.
    func request(address: Address, parameters: Parameters = .init(), userInfo: UserInfo = .init()) async -> SmartResponse {
        return await request(address: address, parameters: parameters, userInfo: userInfo)
    }

    /// ``Void`` request manager.
    var void: TypedRequestManager<Void> {
        return .init(VoidContent(), base: self)
    }

    /// ``Decodable`` request manager.
    var decodable: DecodableRequestManager {
        return .init(base: self)
    }

    // MARK: - strong

    /// ``Data`` request manager.
    var data: TypedRequestManager<Data> {
        return custom(DataContent())
    }

    /// ``Image`` request manager.
    var image: TypedRequestManager<SmartImage> {
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
    var imageOptional: TypedRequestManager<SmartImage?> {
        return customOptional(ImageContent())
    }

    /// ``JSON`` request manager.
    var jsonOptional: TypedRequestManager<Any?> {
        return customOptional(JSONContent())
    }

    // MARK: - custom

    /// Custom request manager which can be used to create a request manager with a custom ``Deserializable`` of your own choice.
    func custom<T: Deserializable>(_ decoder: T) -> TypedRequestManager<T.Object> {
        return .init(decoder, base: self)
    }

    /// Custom request manager which can be used to create a request manager with a custom ``Deserializable`` of your own choice.
    func customOptional<T: Deserializable>(_ type: T) -> TypedRequestManager<T.Object?> {
        return .init(type, base: self)
    }
}
