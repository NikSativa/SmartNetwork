import Foundation

public protocol Plugin {
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestWrapper,
                 userInfo: inout Parameters.UserInfo)

    func verify(data: ResponseData,
                userInfo: Parameters.UserInfo) throws
}
