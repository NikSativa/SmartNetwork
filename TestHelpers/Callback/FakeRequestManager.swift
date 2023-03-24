import Foundation
import NSpry

@testable import NRequest

public final class FakeRequestManager: RequestManagering, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(with:)"
        case requestPureData = "requestPureData(with:)"
        case requestCustomDecodable = "requestCustomDecodable(_:with:)"
        case requestVoid = "requestVoid(with:)"
        case requestDecodable = "requestDecodable(_:with:)"
        case requestImage = "requestImage(with:)"
        case requestOptionalImage = "requestOptionalImage(with:)"
        case requestData = "requestData(with:)"
        case requestOptionalData = "requestOptionalData(with:)"
        case requestAny = "requestAny(with:)"
        case requestOptionalAny = "requestOptionalAny(with:)"
    }

    public init() {}
}
