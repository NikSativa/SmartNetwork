import Combine
import Foundation
import Threading

/// Strategy for requests without stubs
public enum HTTPStubStrategy {
    /// Pass request through to the network
    case transparent

    /// Block with an error and delay
    case blockWithResponse(HTTPStubResponse)

    /// Custom strategy. Return `nil` to pass request through to the network
    case custom(CustomStrategy)
}

/// HTTPStubServer serves as a component responsible for managing stubs and handling network requests for stub responses.
/// Provides methods like add to add a new stub with specific conditions, response details, status code, headers, body, error, and delay.
/// Overall, HTTPStubServer plays a crucial role in managing stubs and facilitating the testing of network request handling in the system.
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

    /// - Parameter path: only for the convenience of the Combine interface
    /// e.g. *stubTask.store(in: &bag)*
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
