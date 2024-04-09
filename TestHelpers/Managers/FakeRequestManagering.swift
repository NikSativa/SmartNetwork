import SmartNetwork
import Foundation
import SpryKit
import Threading

public final class FakeRequestManagering: RequestManagering, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case pure
        case decodable
        case void
        case data
        case image
        case json
        case dataOptional
        case imageOptional
        case jsonOptional
        case request = "custom(type:)"
    }

    public init() {}

    public var pure: PureRequestManager {
        return spryify()
    }

    public var decodable: DecodableRequestManager {
        return spryify()
    }

    public var void: TypedRequestManager<Void> {
        return spryify()
    }

    public var data: TypedRequestManager<Data> {
        return spryify()
    }

    public var image: TypedRequestManager<Image> {
        return spryify()
    }

    public var json: TypedRequestManager<Any> {
        return spryify()
    }

    public var dataOptional: TypedRequestManager<Data?> {
        return spryify()
    }

    public var imageOptional: TypedRequestManager<Image?> {
        return spryify()
    }

    public var jsonOptional: TypedRequestManager<Any?> {
        return spryify()
    }

    public func custom<T: CustomDecodable>(_ type: T.Type) -> TypedRequestManager<T.Object> {
        return spryify(arguments: type)
    }
}
