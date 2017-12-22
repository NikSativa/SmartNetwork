import Foundation

protocol Requestable {
    associatedtype ResponseType
    
    typealias CompleteCallback = (_ result: Result<ResponseType, Error>) -> Void
    func onComplete(_ callback: @escaping CompleteCallback)
    
    func start()
    func stop()
}
