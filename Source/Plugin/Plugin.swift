import Foundation

// sourcery: fakable
public protocol Plugin {
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestable,
                 userInfo: inout Parameters.UserInfo)

    func willSend(_ parameters: Parameters,
                  request: URLRequestable)
    func didReceive(_ parameters: Parameters,
                    data: ResponseData)
    func didFinish(_ parameters: Parameters,
                   data: ResponseData,
                   dto: Any?)

    func verify(data: ResponseData) throws
}
