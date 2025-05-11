import Foundation
import Threading

/// Defines an interface for sending network requests with configurable parameters and response handling.
///
/// `RequestManager` is responsible for constructing and executing HTTP requests to a specified `Address`
/// using a given `Parameters` configuration. It supports both async/await and completion-based request patterns.
public protocol RequestManager: SmartSendable {
    /// A closure that gets called upon receiving a response.
    typealias ResponseClosure = (_ result: SmartResponse) -> Void

    /// Sends a request asynchronously to the specified address with the given parameters and user metadata.
    ///
    /// - Parameters:
    ///   - address: The target endpoint.
    ///   - parameters: Request configuration parameters.
    ///   - userInfo: Contextual metadata for the request.
    /// - Returns: A `SmartResponse` containing the result of the network operation.
    func request(address: Address, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse

    /// Sends a request using a completion handler, executed on the specified queue.
    ///
    /// - Parameters:
    ///   - address: The target endpoint.
    ///   - parameters: Request configuration parameters.
    ///   - userInfo: Contextual metadata for the request.
    ///   - completionQueue: The dispatch queue for the completion handler.
    ///   - completion: Closure that receives the result as a `SmartResponse`.
    /// - Returns: A `SmartTasking` handle representing the in-flight request.
    func request(address: Address, parameters: Parameters, userInfo: UserInfo, completionQueue: DelayedQueue, completion: @escaping ResponseClosure) -> SmartTasking
}

public extension RequestManager {
    /// Wraps the request in a generic, untyped `AnyRequest` for flexible usage.
    ///
    /// - Parameters:
    ///   - address: The target endpoint.
    ///   - parameters: Optional request configuration. Defaults to `.init()`.
    ///   - userInfo: Optional metadata. Defaults to `.init()`.
    /// - Returns: A lazily-executed `AnyRequest`.
    func request(address: Address, parameters: Parameters = .init(), userInfo: UserInfo = .init()) -> AnyRequest {
        return .init(pure: self, address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Asynchronously sends a request using default parameters and user info.
    func request(address: Address, parameters: Parameters = .init(), userInfo: UserInfo = .init()) async -> SmartResponse {
        return await request(address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Returns a request manager that deserializes responses as `Void`.
    var void: TypedRequestManager<Void> {
        return .init(VoidContent(), base: self)
    }

    /// Returns a request manager configured to deserialize the response as a `Decodable` type.
    var decodable: DecodableRequestManager {
        return .init(base: self)
    }

    // MARK: - strong

    /// Returns a request manager configured to decode the response as raw `Data`.
    var data: TypedRequestManager<Data> {
        return custom(DataContent())
    }

    /// Returns a request manager configured to decode the response as a `SmartImage`.
    var image: TypedRequestManager<SmartImage> {
        return custom(ImageContent())
    }

    /// Returns a request manager configured to decode the response as JSON (`Any`).
    var json: TypedRequestManager<Any> {
        return custom(JSONContent())
    }

    // MARK: - optional

    /// Returns a request manager configured to decode the response as optional `Data`.
    var dataOptional: TypedRequestManager<Data?> {
        return customOptional(DataContent())
    }

    /// Returns a request manager configured to decode the response as optional `SmartImage`.
    var imageOptional: TypedRequestManager<SmartImage?> {
        return customOptional(ImageContent())
    }

    /// Returns a request manager that decodes the response as optional JSON (`Any?`).
    var jsonOptional: TypedRequestManager<Any?> {
        return customOptional(JSONContent())
    }

    // MARK: - custom

    /// Creates a custom typed request manager using the specified deserializer.
    ///
    /// - Parameter decoder: A custom deserializer conforming to `Deserializable`.
    /// - Returns: A typed request manager using the provided decoder.
    func custom<T: Deserializable>(_ decoder: T) -> TypedRequestManager<T.Object> {
        return .init(decoder, base: self)
    }

    /// Creates a custom typed request manager using the specified deserializer.
    ///
    /// - Parameter decoder: A custom deserializer conforming to `Deserializable`.
    /// - Returns: A typed request manager using the provided decoder.
    func customOptional<T: Deserializable>(_ type: T) -> TypedRequestManager<T.Object?> {
        return .init(type, base: self)
    }
}
