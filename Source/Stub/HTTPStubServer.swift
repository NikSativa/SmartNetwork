import Combine
import Foundation
import Threading

/// Defines fallback behavior for handling network requests that do not match any registered stubs.
///
/// Used by `HTTPStubServer` when no condition is satisfied for an incoming request.
public enum HTTPStubStrategy {
    /// Pass request through to the network
    case transparent

    /// Block with an error and delay
    case blockWithResponse(HTTPStubResponse)

    /// Custom strategy. Return `nil` to pass request through to the network
    case custom(CustomStrategy)
}

/// A stub server that intercepts and optionally mocks network requests for testing.
///
/// `HTTPStubServer` maintains a list of registered conditions and responses used to simulate network behavior.
/// It supports Combine-based task management, configurable default strategies for unmatched requests, and
/// integration with `URLProtocol` for intercepting system-level networking.
public final class HTTPStubServer {
    #if swift(>=6.0)
    /// Default queue for stubs
    public nonisolated(unsafe) static var defaultCompletionQueue: Queueable = Queue.main

    /// Strategy for requests without stubs
    public nonisolated(unsafe) static var strategy: HTTPStubStrategy = .transparent
    #else
    /// Default queue for stubs
    public static var defaultCompletionQueue: Queueable = Queue.main

    /// Strategy for requests without stubs
    public static var strategy: HTTPStubStrategy = .transparent
    #endif

    public static let shared: HTTPStubServer = .init()

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var responses: [Info] = []

    private init() {
        let registered = URLProtocol.registerClass(HTTPStubProtocol.self)
        assert(registered, "HTTPStubProtocol registration failed")
    }

    /// Registers a new stubbed response for requests matching the given condition.
    ///
    /// This version supports integration with Combine by returning a `SmartTasking` that can be stored or cancelled.
    /// Cancelling the returned task removes the stub.
    ///
    /// - Parameters:
    ///   - condition: A closure or matcher used to test incoming requests.
    ///   - response: The stubbed response to return for matching requests.
    /// - Returns: A `SmartTasking` instance for cancellation.
    public func add(condition: HTTPStubCondition,
                    response: HTTPStubResponse) -> SmartTasking {
        return $responses.mutate { responses in
            let id = UUID().uuidString
            let info = Info(id: id,
                            condition: condition,
                            response: response)
            responses.append(info)

            return SmartTask(runAction: {
                // nothing to do
            }) { [self] in
                removeAll(withId: id)
            }
        }
    }

    private func removeAll(withId id: String) {
        $responses.mutate { responses in
            responses.removeAll(where: { info in
                return info.id == id
            })
        }
    }

    /// Resolves a stubbed response for a given request, falling back to the configured strategy if none match.
    internal func response(for request: URLRequestRepresentation) -> HTTPStubResponse? {
        return $responses.mutate { responses in
            let found = responses.first { info in
                return info.condition.test(request)
            }

            if let response = found?.response {
                return response
            }

            switch Self.strategy {
            case .transparent:
                return nil
            case .blockWithResponse(let response):
                return response
            case .custom(let block):
                return block(request)
            }
        }
    }
}

public extension HTTPStubServer {
    /// Convenience method to register a stub response using individual components.
    ///
    /// Builds an `HTTPStubResponse` from status code, headers, body, error, and delay before registering.
    func add(condition: HTTPStubCondition,
             statusCode: StatusCode = 200,
             header: HeaderFields = [:],
             body: HTTPStubBody? = nil,
             error: Error? = nil,
             delayInSeconds: TimeInterval? = nil) -> SmartTasking {
        let response: HTTPStubResponse = .init(statusCode: statusCode,
                                               header: header,
                                               body: body,
                                               error: error,
                                               delayInSeconds: delayInSeconds)
        return add(condition: condition, response: response)
    }
}

// MARK: - HTTPStubServer.Info

private extension HTTPStubServer {
    /// Internal structure representing a stub entry including its ID, condition, and response.
    struct Info {
        let id: String
        let condition: HTTPStubCondition
        let response: HTTPStubResponse
    }
}

#if swift(>=6.0)
extension HTTPStubServer: @unchecked Sendable {}
extension HTTPStubServer.Info: Sendable {}
extension HTTPStubStrategy: Sendable {
    public typealias CustomStrategy = @Sendable (URLRequestRepresentation) -> HTTPStubResponse?
}
#else
public extension HTTPStubStrategy {
    typealias CustomStrategy = (URLRequestRepresentation) -> HTTPStubResponse?
}
#endif
