//import Foundation
//import UIKit
//import NCallback
//
//public protocol RequestFactory: class {
//    associatedtype Error: AnyError
//
//    func request<T: CustomDecodable, R: Request>(_: T.Type, with parameters: Parameters) -> R where R.Error == Error, R.Response == T.Object
//
//    /// proxy helpers
//    func requestIgnorable<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Ignorable
//
//    func request<R: Request>(_: R.Response.Type, with parameters: Parameters) -> R where R.Error == Error, R.Response: Decodable
//    func request<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response: Decodable
//
//    func requestImage<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == UIImage
//    func requestOptionalImage<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == UIImage?
//
//    func requestData<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Data
//    func requestOptionalData<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Data?
//
//    func requestAny<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Any
//    func requestOptionalAny<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Any?
//
//    /// convert to AnyRequestFactory
//    func toAny() -> AnyRequestFactory<Error>
//}
//
//public extension RequestFactory {
//    // MARK - Ignorable
//    func requestIgnorable<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Ignorable {
//        request(IgnorableContent<R.Error>.self, with: parameters)
//    }
//
//    // MARK - Decodable
//    func request<R: Request>(_: R.Response.Type, with parameters: Parameters) -> R where R.Error == Error, R.Response: Decodable {
//        request(DecodableContent<R.Response, R.Error>.self, with: parameters)
//    }
//
//    func request<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response: Decodable {
//        request(DecodableContent<R.Response, R.Error>.self, with: parameters)
//    }
//
//    // MARK - Image
//    func requestImage<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == UIImage {
//        request(ImageContent<R.Error>.self, with: parameters)
//    }
//
//    func requestOptionalImage<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == UIImage? {
//        request(OptionalImageContent<R.Error>.self, with: parameters)
//    }
//
//    // MARK - Data
//    func requestData<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Data {
//        request(DataContent<R.Error>.self, with: parameters)
//    }
//
//    func requestOptionalData<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Data? {
//        request(OptionalDataContent<R.Error>.self, with: parameters)
//    }
//
//    // MARK - Any/JSON
//    func requestAny<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Any {
//        request(JSONContent<R.Error>.self, with: parameters)
//    }
//
//    func requestOptionalAny<R: Request>(with parameters: Parameters) -> R where R.Error == Error, R.Response == Any? {
//        request(OptionalJSONContent<R.Error>.self, with: parameters)
//    }
//
//    // MARK -
//    func toAny() -> AnyRequestFactory<Error> {
//        if let self = self as? AnyRequestFactory<Error> {
//            return self
//        }
//
//        return AnyRequestFactory(self)
//    }
//}
