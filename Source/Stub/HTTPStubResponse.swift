import Foundation

struct HTTPStubResponse {
    let statusCode: Int
    let header: HeaderFields
    let body: HTTPStubBody
    let delayInSeconds: TimeInterval?
}
