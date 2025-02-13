import Foundation
import Threading

/// A protocol for stubbing HTTP responses.
public final class HTTPStubProtocol: URLProtocol {
    override public class func canInit(with request: URLRequest) -> Bool {
        let response = HTTPStubServer.shared.response(for: request)
        return response != nil
    }

    override public class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.originalRequest ?? task.currentRequest else {
            return false
        }
        let response = HTTPStubServer.shared.response(for: request)
        return response != nil
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        guard let client else {
            assertionFailure("should never happen")
            return
        }

        guard let stub = HTTPStubServer.shared.response(for: request) else {
            Queue.background.async { [request] in
                let error = NSError(domain: "<HTTPStub> no stub for \(request.url?.absoluteString ?? "<broken url>")", code: -1)
                client.urlProtocol(self, didFailWithError: error)
                client.urlProtocolDidFinishLoading(self)
            }
            return
        }

        let response: URLResponse = request.url.flatMap { url in
            return stub.urlResponse(url: url)
        } ?? .init()

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        let delayInSeconds = stub.delayInSeconds ?? 0
        Queue.background.asyncAfter(deadline: .now() + delayInSeconds) { [self, client] in
            if let error = stub.error {
                client.urlProtocol(self, didFailWithError: error)
            } else if let data = stub.body?.data {
                client.urlProtocol(self, didLoad: data)
            }

            client.urlProtocolDidFinishLoading(self)
        }
    }

    override public func stopLoading() {}
}

#if swift(>=6.0)
extension HTTPStubProtocol: @unchecked Sendable {}
#endif
