import Foundation

// MARK: - URLSession + SmartURLSession

extension URLSession: SmartURLSession {
    public func task(for request: URLRequest) async throws -> (AsyncBytes, URLResponse) {
        return try await bytes(for: request)
    }
}
