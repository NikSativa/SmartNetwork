import Foundation

#if swift(>=6.0)
public protocol RequestManagering: Sendable {
    // MARK: -

    var pure: PureRequestManager { get }
    var decodable: DecodableRequestManager { get }
    var void: TypedRequestManager<Void> { get }

    // MARK: - strong

    var data: TypedRequestManager<Data> { get }

    var image: TypedRequestManager<Image> { get }
    var json: TypedRequestManager<Any> { get }

    // MARK: - optional

    var dataOptional: TypedRequestManager<Data?> { get }
    var imageOptional: TypedRequestManager<Image?> { get }
    var jsonOptional: TypedRequestManager<Any?> { get }

    // MARK: - custom

    func custom<T: CustomDecodable>(_ type: T.Type) -> TypedRequestManager<T.Object>
}
#else
public protocol RequestManagering {
    // MARK: -

    var pure: PureRequestManager { get }
    var decodable: DecodableRequestManager { get }
    var void: TypedRequestManager<Void> { get }

    // MARK: - strong

    var data: TypedRequestManager<Data> { get }

    var image: TypedRequestManager<Image> { get }
    var json: TypedRequestManager<Any> { get }

    // MARK: - optional

    var dataOptional: TypedRequestManager<Data?> { get }
    var imageOptional: TypedRequestManager<Image?> { get }
    var jsonOptional: TypedRequestManager<Any?> { get }

    // MARK: - custom

    func custom<T: CustomDecodable>(_ type: T.Type) -> TypedRequestManager<T.Object>
}
#endif
