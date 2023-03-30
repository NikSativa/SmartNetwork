import Combine
import Foundation
import NQueue

public final class HTTPStubServer {
    static let shared: HTTPStubServer = .init()

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var responses: [Info] = []
    private var counter: UInt = 0

    private init() {
        let registered = URLProtocol.registerClass(HTTPStubProtocol.self)
        assert(registered)
    }

    /// - Parameter path: only for the convenience of the Combine interface
    /// e.g. *stubTask.store(in: &bag)*
    public func add(condition: HTTPStubCondition,
                    statusCode: Int = 200,
                    header: HeaderFields = [:],
                    body: HTTPStubBody = .empty,
                    error: Error? = nil,
                    delayInSeconds: TimeInterval? = nil) -> AnyCancellable {
        return $responses.mutate { responses in
            let response = HTTPStubResponse(statusCode: statusCode,
                                            header: header,
                                            body: body,
                                            error: error,
                                            delayInSeconds: delayInSeconds)
            let id = counter
            counter &+= 1

            let info = Info(id: id,
                            condition: condition,
                            response: response)
            responses.append(info)

            let task = AnyCancellable { [weak self] in
                self?.responses.removeAll(where: { info in
                    return info.id == id
                })
            }
            return task
        }
    }

    func response(for request: URLRequest) -> HTTPStubResponse? {
        return $responses.mutate { responses in
            let found = responses.first { info in
                return info.condition.test(request)
            }
            return found?.response
        }
    }
}

// MARK: - HTTPStubServer.Info

private extension HTTPStubServer {
    struct Info {
        let id: UInt
        let condition: HTTPStubCondition
        let response: HTTPStubResponse
    }
}
