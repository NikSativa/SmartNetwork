import Foundation

/// Defines logic for conditionally halting or continuing the network request pipeline in `SmartRequestManager`.
///
/// `StopTheLine` allows you to intercept the flow of request execution based on the contents of a response.
/// This can be used for custom validation, centralized error handling, or automated retry logic.
///
/// See diagram: ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
public protocol StopTheLine: SmartSendable {
    /// Determines the result of a stop-the-line evaluation by inspecting the full request context.
    ///
    /// - Parameters:
    ///   - manager: The active `SmartRequestManager` executing the request.
    ///   - response: The response received for the current request.
    ///   - address: The request address.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineResult` that dictates how the pipeline should proceed.
    /// - Throws: Can throw if validation or custom logic requires it.
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult

    /// Performs lightweight verification on the response to decide whether to stop, continue, or retry.
    ///
    /// - Parameters:
    ///   - response: The response received.
    ///   - address: The request address.
    ///   - parameters: The associated request parameters.
    ///   - userInfo: The user info context for this request.
    /// - Returns: A `StopTheLineAction` representing the verification result.
    func verify(response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
