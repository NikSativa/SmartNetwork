import Foundation
import UIKit

//final
//public class AnyRequest<Response, Error: AnyError>: Request {
//    private let box: AbstractRequest<Response, Error>
//
//    public init<K: Request>(_ provider: K) where K.Error == Error, K.Response == Response {
//        self.box = RequestBox(provider)
//    }
//
//    public func start() {
//        box.start()
//    }
//
//    public func stop() {
//        box.stop()
//    }
//
//    public func onComplete(_ callback: @escaping CompleteCallback) {
//        box.onComplete(callback)
//    }
//}
//
//private class AbstractRequest<Response, Error: AnyError>: Request {
//    public func start() {
//        fatalError("abstract needs override")
//    }
//
//    public func stop() {
//        fatalError("abstract needs override")
//    }
//
//    public func onComplete(_ callback: @escaping CompleteCallback) {
//        fatalError("abstract needs override")
//    }
//}
//
//final
//private class RequestBox<T: Request>: AbstractRequest<T.Response, T.Error> {
//    private var concrete: T
//
//    init(_ concrete: T) {
//        self.concrete = concrete
//    }
//
//    public override func start() {
//        concrete.start()
//    }
//
//    public override func stop() {
//        concrete.stop()
//    }
//
//    public override func onComplete(_ callback: @escaping CompleteCallback) {
//        concrete.onComplete(callback)
//    }
//}
