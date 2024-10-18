import Foundation

#if swift(>=6.0)
/// The RequestManagering protocol in Swift serves as an interface that defines the requirements for managing requests within the system.
/// It extends the Sendable protocol and provides access to various request manager types,
/// such as PureRequestManager, DecodableRequestManager, TypedRequestManager<Void>, and TypedRequestManager<Data>.
/// The protocol enforces the implementation of these properties,
/// allowing for a standardized way to interact with request management functionalities.
/// By conforming to the RequestManagering protocol, classes can ensure consistency in handling request-related tasks and data processing.
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
/// The RequestManagering protocol in Swift serves as an interface that defines the requirements for managing requests within the system.
/// It extends the Sendable protocol and provides access to various request manager types,
/// such as PureRequestManager, DecodableRequestManager, TypedRequestManager<Void>, and TypedRequestManager<Data>.
/// The protocol enforces the implementation of these properties,
/// allowing for a standardized way to interact with request management functionalities.
/// By conforming to the RequestManagering protocol, classes can ensure consistency in handling request-related tasks and data processing.
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
