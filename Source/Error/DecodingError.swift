import Foundation

public enum DecodingError: Error, Equatable {
    case brokenResponse
    case nilResponse
}

extension DecodingError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .brokenResponse:
            return 0
        case .nilResponse:
            return 1
        }
    }
    
    public var errorUserInfo: [String : Any] {
        switch self {
        case .brokenResponse:
            return [:]
        case .nilResponse:
            return [:]
        }
    }
}
