import Foundation

final class HTTPStubServer {
    static let shared: HTTPStubServer = .init()

    private var responses: [(condition: HTTPStubCondition, response: HTTPStubResponse)] = []

    func add(condition: HTTPStubCondition,
             statusCode: Int? = nil,
             header: HeaderFields = [:],
             body: HTTPStubBody = .empty) {
        let response = HTTPStubResponse(statusCode: statusCode,
                                        header: header,
                                        body: body)
        responses.append((condition, response))
    }
}
