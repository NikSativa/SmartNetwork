import Foundation
import Threading

/// A custom `URLProtocol` implementation that intercepts requests and provides stubbed responses.
///
/// `HTTPStubProtocol` is used internally by `HTTPStubServer` to simulate network responses for testing purposes.
/// When registered with `URLProtocol`, it checks whether a stubbed response exists for a request and delivers it
/// with optional delay, body, and error simulation.
public final class HTTPStubProtocol: URLProtocol {
    /// Determines whether this protocol can handle the specified request.
    ///
    /// - Parameter request: The request to evaluate.
    /// - Returns: `true` if a stubbed response exists; otherwise, `false`.
    override public class func canInit(with request: URLRequest) -> Bool {
        let response = HTTPStubServer.shared.response(for: request)
        return response != nil
    }

    /// Determines whether this protocol can handle the request associated with the given task.
    ///
    /// - Parameter task: The URL session task whose request should be evaluated.
    /// - Returns: `true` if a stubbed response exists; otherwise, `false`.
    override public class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.originalRequest ?? task.currentRequest else {
            return false
        }

        let response = HTTPStubServer.shared.response(for: request)
        return response != nil
    }

    /// Returns a canonical version of the request. Used to standardize how requests are cached or compared.
    ///
    /// - Parameter request: The request to canonicalize.
    /// - Returns: The original request unchanged.
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    /// Begins loading the stubbed response for the intercepted request.
    ///
    /// Delivers a simulated response to the client, optionally including data, delay, or error.
    /// If no stub is found, a descriptive error is returned.
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

    /// Stops handling the request. No-op in the stubbed implementation.
    override public func stopLoading() {}
}

#if swift(>=6.0)
/// Marks the protocol implementation as unchecked `Sendable` for use in Swift concurrency contexts.
extension HTTPStubProtocol: @unchecked Sendable {}
#endif
