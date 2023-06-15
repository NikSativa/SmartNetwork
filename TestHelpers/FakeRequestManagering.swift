import Foundation
import NQueue
import NSpry

@testable import NRequest

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

    public var pure: NRequest.PureRequestManager {
        return spryify()
    }

    public var decodable: NRequest.DecodableRequestManager {
        return spryify()
    }

    public var void: NRequest.TypedRequestManager<Void> {
        return spryify()
    }

    public var data: NRequest.TypedRequestManager<Data> {
        return spryify()
    }

    public var image: NRequest.TypedRequestManager<NRequest.Image> {
        return spryify()
    }

    public var json: NRequest.TypedRequestManager<Any> {
        return spryify()
    }

    public var dataOptional: NRequest.TypedRequestManager<Data?> {
        return spryify()
    }

    public var imageOptional: NRequest.TypedRequestManager<NRequest.Image?> {
        return spryify()
    }

    public var jsonOptional: NRequest.TypedRequestManager<Any?> {
        return spryify()
    }

    public func custom<T: NRequest.CustomDecodable>(_ type: T.Type) -> NRequest.TypedRequestManager<T.Object> {
        return spryify(arguments: type)
    }
}
