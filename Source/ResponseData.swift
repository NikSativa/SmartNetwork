import Foundation

#warning("rename to RequestResult")
public final class ResponseData {
    public let request: URLRequestRepresentation?
    public let body: Data?
    public let response: URLResponse?
    public private(set) var error: Error?

    public lazy var url: URL? = (response as? HTTPURLResponse)?.url

    public lazy var allHeaderFields: [AnyHashable: Any] = {
        return (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
    }()

    public lazy var statusCode: Int? = (response as? HTTPURLResponse)?.statusCode

    public lazy var urlError: URLError? = error as? URLError

    init(request: URLRequestRepresentation?,
         body: Data?,
         response: URLResponse?,
         error: Error?) {
        self.request = request
        self.body = body
        self.response = response
        self.error = error
    }

    func set(_ error: Error?) {
        self.error = error
    }
}
