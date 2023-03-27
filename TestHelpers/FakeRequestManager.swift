// import Foundation
// import NSpry
//
// @testable import NRequest
//
// public final class FakeRequestManager<Error: AnyError>: RequestManager, Spryable {
//    public enum ClassFunction: String, StringRepresentable {
//        case empty
//    }
//
//    public enum Function: String, StringRepresentable {
//        case request = "request(with:)"
//        case requestPureData = "requestPureData(with:)"
//        case requestCustomDecodable = "requestCustomDecodable(_:with:)"
//        case requestVoid = "requestVoid(with:)"
//        case requestDecodable = "requestDecodable(_:with:)"
//        case requestImage = "requestImage(with:)"
//        case requestOptionalImage = "requestOptionalImage(with:)"
//        case requestData = "requestData(with:)"
//        case requestOptionalData = "requestOptionalData(with:)"
//        case requestAny = "requestAny(with:)"
//        case requestOptionalAny = "requestOptionalAny(with:)"
//    }
//
//    public init() {}
//
//    public func requestPureData(with parameters: Parameters) -> Callback<RequestResult> {
//        return spryify(arguments: parameters)
//    }
//
//    public func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error> {
//        return spryify(arguments: type, parameters)
//    }
//
//    // MARK: - Void
//
//    public func requestVoid(with parameters: Parameters) -> ResultCallback<Void, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    // MARK: - Decodable
//
//    public func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
//        return spryify(arguments: type, parameters)
//    }
//
//    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    // MARK: - Image
//
//    public func requestImage(with parameters: Parameters) -> ResultCallback<Image, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    public func requestOptionalImage(with parameters: Parameters) -> ResultCallback<Image?, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    // MARK: - Data
//
//    public func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    public func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    // MARK: - Any/JSON
//
//    public func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
//        return spryify(arguments: parameters)
//    }
//
//    public func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
//        return spryify(arguments: parameters)
//    }
// }
