import Foundation
import Threading

/// Defines an interface for sending network requests with configurable parameters and response handling.
///
/// `RequestManager` is responsible for constructing and executing HTTP requests to a specified endpoint
/// using a given `Parameters` configuration. It supports both async/await and completion-based request patterns.
public protocol RequestManager: SmartSendable {
    /// A closure that gets called upon receiving a response.
    typealias ResponseClosure = (_ result: SmartResponse) -> Void

    /// Sends a request asynchronously to the specified endpoint with the given parameters and user metadata.
    func request(url: SmartURL, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse

    /// Sends a request using a completion handler, executed on the specified queue.
    func request(url: SmartURL,
                 parameters: Parameters,
                 userInfo: UserInfo,
                 completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking
}

public extension RequestManager {
    // MARK: - Completion helpers

    /// Sends a request using a completion handler, executed on the specified queue.
    func request(url: URL,
                 parameters: Parameters,
                 userInfo: UserInfo,
                 completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking {
        return request(url: .url(url),
                       parameters: parameters,
                       userInfo: userInfo,
                       completionQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request using a completion handler and default `Parameters` and `UserInfo`.
    func request(url: SmartURL,
                 completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking {
        return request(url: url,
                       parameters: .init(),
                       userInfo: .init(),
                       completionQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request using a completion handler and default `UserInfo`.
    func request(url: SmartURL,
                 parameters: Parameters,
                 completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking {
        return request(url: url,
                       parameters: parameters,
                       userInfo: .init(),
                       completionQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request using a completion handler and default `Parameters`.
    func request(url: SmartURL,
                 userInfo: UserInfo,
                 completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking {
        return request(url: url,
                       parameters: .init(),
                       userInfo: userInfo,
                       completionQueue: completionQueue,
                       completion: completion)
    }

    // MARK: - AnyRequest

    /// Wraps the request in a generic, untyped `AnyRequest` for flexible usage.
    func request(url: SmartURL, parameters: Parameters = .init(), userInfo: UserInfo = .init()) -> AnyRequest {
        return .init(pure: self, url: url, parameters: parameters, userInfo: userInfo)
    }

    /// Wraps the request in a generic, untyped `AnyRequest` for flexible usage.
    func request(url: URL, parameters: Parameters = .init(), userInfo: UserInfo = .init()) -> AnyRequest {
        return request(url: .url(url), parameters: parameters, userInfo: userInfo)
    }

    // MARK: - Async helpers

    /// Asynchronously sends a request with default `Parameters` and `UserInfo`.
    func request(url: SmartURL) async -> SmartResponse {
        return await request(url: url,
                             parameters: .init(),
                             userInfo: .init())
    }

    /// Asynchronously sends a request with default `UserInfo`.
    func request(url: SmartURL, parameters: Parameters) async -> SmartResponse {
        return await request(url: url,
                             parameters: parameters,
                             userInfo: .init())
    }

    /// Asynchronously sends a request with default `Parameters`.
    func request(url: SmartURL, userInfo: UserInfo) async -> SmartResponse {
        return await request(url: url,
                             parameters: .init(),
                             userInfo: userInfo)
    }

    /// Asynchronously sends a request with default `Parameters` and `UserInfo`.
    func request(url: URL) async -> SmartResponse {
        return await request(url: .url(url),
                             parameters: .init(),
                             userInfo: .init())
    }

    /// Asynchronously sends a request with default `UserInfo`.
    func request(url: URL, parameters: Parameters) async -> SmartResponse {
        return await request(url: .url(url),
                             parameters: parameters,
                             userInfo: .init())
    }

    /// Asynchronously sends a request with default `Parameters`.
    func request(url: URL, userInfo: UserInfo) async -> SmartResponse {
        return await request(url: .url(url),
                             parameters: .init(),
                             userInfo: userInfo)
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
