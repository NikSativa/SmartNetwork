import Foundation

/// Defines logic for conditionally halting or continuing the network request pipeline in `SmartRequestManager`.
///
/// `StopTheLine` allows you to intercept the flow of request execution based on the contents of a response.
/// This can be used for custom validation, centralized error handling, or automated retry logic.
///
/// - SeeAlso: [Architecture Overview](https://github.com/NikSativa/SmartNetwork#architecture-overview)
public protocol StopTheLine: SmartSendable {
    /// Determines the result of a stop-the-line evaluation by inspecting the full request context.
    ///
    /// - Parameters:
    ///   - manager: The active `SmartRequestManager` executing the request.
    ///   - response: The response received for the current request.
    ///   - url: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineResult` that dictates how the pipeline should proceed.
    /// - Throws: Can throw if validation or custom logic requires it.
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult

    /// Performs lightweight verification on the response to decide whether to stop, continue, or retry.
    ///
    /// - Parameters:
    ///   - response: The response received.
    ///   - url: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineAction` representing the verification result.
    func verify(response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}

public extension StopTheLine {
    /// Determines the result of a stop-the-line evaluation by inspecting the full request context.
    ///
    /// - Parameters:
    ///   - manager: The active `SmartRequestManager` executing the request.
    ///   - response: The response received for the current request.
    ///   - address: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineResult` that dictates how the pipeline should proceed.
    /// - Throws: Can throw if validation or custom logic requires it.
    @available(*, deprecated, renamed: "action(with:response:url:parameters:userInfo:)", message: "Please use action(with:response:url:parameters:userInfo:) instead.")
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                address: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult {
        return try await action(with: manager,
                                response: response,
                                url: address,
                                parameters: parameters,
                                userInfo: userInfo)
    }

    /// Determines the result of a stop-the-line evaluation by inspecting the full request context.
    ///
    /// - Parameters:
    ///   - manager: The active `SmartRequestManager` executing the request.
    ///   - response: The response received for the current request.
    ///   - url: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineResult` that dictates how the pipeline should proceed.
    /// - Throws: Can throw if validation or custom logic requires it.
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                url: URL,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult {
        return try await action(with: manager,
                                response: response,
                                url: .url(url),
                                parameters: parameters,
                                userInfo: userInfo)
    }

    /// Performs lightweight verification on the response to decide whether to stop, continue, or retry.
    ///
    /// - Parameters:
    ///   - response: The response received.
    ///   - address: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineAction` representing the verification result.
    @available(*, deprecated, renamed: "verify(response:url:parameters:userInfo:)", message: "Please use verify(response:url:parameters:userInfo:) instead.")
    func verify(response: SmartResponse,
                address: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction {
        return verify(response: response,
                      url: address,
                      parameters: parameters,
                      userInfo: userInfo)
    }

    /// Performs lightweight verification on the response to decide whether to stop, continue, or retry.
    ///
    /// - Parameters:
    ///   - response: The response received.
    ///   - url: The request url.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineAction` representing the verification result.
    func verify(response: SmartResponse,
                url: URL,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction {
        return verify(response: response,
                      url: .url(url),
                      parameters: parameters,
                      userInfo: userInfo)
    }
}
