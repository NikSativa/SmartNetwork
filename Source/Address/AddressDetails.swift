import Foundation

/// The ``AddressDetails`` struct in Swift represents a ``URL`` and contains specific components to define the address details.
/// This struct is intended to encapsulate detailed information about a ``URL``, such as scheme, host, port,
/// path components, query items, and fragment for constructing and processing ``URL``s effectively within the system.
public struct AddressDetails: Hashable, SmartSendable {
    public let scheme: Scheme?
    public let host: String
    public let port: Int?
    public let path: [String]
    public let queryItems: QueryItems
    public let fragment: String?

    public init(scheme: Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [:],
                fragment: String? = nil) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryItems = queryItems
        self.fragment = fragment
    }
}

public extension AddressDetails {
    init(components: URLComponents) throws {
        self.scheme = components.scheme.sdk
        self.host = try components.host.unwrap(orThrow: RequestEncodingError.brokenHost)
        self.port = components.port
        self.path = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        self.fragment = components.fragment

        let items: [SmartItem<String?>] = (components.queryItems ?? []).map {
            return .init(key: $0.name, value: $0.value)
        }
        self.queryItems = .init(items)
    }

    init(url: URL) throws {
        let components = try URLComponents(url: url, resolvingAgainstBaseURL: true).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(components: components)
    }

    init(string: String) throws {
        let url = try URL(string: string).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(url: url)
    }
}

// MARK: - CustomDebugStringConvertible

extension AddressDetails: CustomDebugStringConvertible {
    public var debugDescription: String {
        return makeDescription()
    }
}

// MARK: - CustomStringConvertible

extension AddressDetails: CustomStringConvertible {
    public var description: String {
        return makeDescription()
    }
}

private extension AddressDetails {
    private func makeDescription() -> String {
        let text: [String?] = [
            scheme?.toString().map { "\($0)://" },
            host,
            port.map { ":\($0)" },
            path.isEmpty ? nil : "/",
            path.joined(separator: "/"),
            queryItems.isEmpty ? nil : "?",
            queryItems.mapToDescription().map {
                if let value = $0.value {
                    return "\($0.key)=\(value)"
                }
                return $0.key
            }.joined(separator: "&"),
            fragment.map { "#\($0)" }
        ]

        return text.filterNils().joined()
    }
}

private extension String? {
    var sdk: Scheme? {
        guard let self, !self.isEmpty else {
            return nil
        }

        if self.hasPrefix("https") {
            return .https
        } else if self.hasPrefix("http") {
            return .http
        } else {
            return .other(self)
        }
    }
}
