import Foundation

struct HTTPStubResponse {
    let statusCode: Int
    let header: HeaderFields
    let body: HTTPStubBody
    let error: Error?
    let delayInSeconds: TimeInterval?
}
