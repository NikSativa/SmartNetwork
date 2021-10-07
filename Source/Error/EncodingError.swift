import Foundation

public enum EncodingError: Error, Equatable {
    case generic(EquatableError)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON
}

extension EncodingError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .generic:
            return 0
        case .lackParameters:
            return 1
        case .lackAdress:
            return 2
        case .cantEncodeImage:
            return 3
        case .invalidJSON:
            return 4
        }
    }
    
    public var errorUserInfo: [String : Any] {
        switch self {
        case .generic(let error):
            return ["error": error]
        case .lackParameters:
            return [:]
        case .lackAdress:
            return [:]
        case .cantEncodeImage:
            return [:]
        case .invalidJSON:
            return [:]
        }
    }
}
