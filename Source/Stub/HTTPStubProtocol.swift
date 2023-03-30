import Foundation
import NQueue

public final class HTTPStubProtocol: URLProtocol {
    override public class func canInit(with request: URLRequest) -> Bool {
        let response = HTTPStubServer.shared.response(for: request)
        return response != nil
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        do {
            guard let stub = HTTPStubServer.shared.response(for: request) else {
                throw RequestError.generic
            }

            guard let response = HTTPURLResponse(url: request.url.unsafelyUnwrapped,
                                                 statusCode: stub.statusCode,
                                                 httpVersion: "HTTP/1.1",
                                                 headerFields: stub.header) else {
                throw RequestError.generic
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            Queue.background.asyncAfter(deadline: .now() + 0) {
                if let error = stub.error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                    return
                }

                if let data = stub.body.data {
                    self.client?.urlProtocol(self, didLoad: data)
                }

                self.client?.urlProtocolDidFinishLoading(self)
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}
}
