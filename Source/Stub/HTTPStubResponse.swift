import Foundation

public struct HTTPStubResponse {
    public let statusCode: StatusCode
    public let header: HeaderFields
    public let body: HTTPStubBody
    public let error: Error?
    public let delayInSeconds: TimeInterval?

    public init(statusCode: StatusCode = 200,
                header: HeaderFields = [:],
                body: HTTPStubBody = .empty,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }

    public init(statusCode: StatusCode.Kind,
                header: HeaderFields = [:],
                body: HTTPStubBody = .empty,
                error: Error? = nil,
                delayInSeconds: TimeInterval? = nil) {
        let statusCode = StatusCode(statusCode)
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.error = error
        self.delayInSeconds = delayInSeconds
    }
}
