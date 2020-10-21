import Foundation

public protocol Plugin {
    typealias Info = RequestInfo

    func prepare(_ info: inout Info)
    func willSend(_ info: Info)
    func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?)

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws
}
