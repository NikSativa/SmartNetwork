import Foundation

// sourcery: fakable
public protocol Plugin {
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestable,
                 userInfo: inout Parameters.UserInfo)

    func willSend(_ parameters: Parameters,
                  request: URLRequestable)
    func didFinish(_ parameters: Parameters,
                   request: URLRequestable,
                   data: ResponseData)

    func verify(data: ResponseData) throws
}
