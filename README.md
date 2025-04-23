# SmartNetwork

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![Supported Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![CI](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml)
[![License](https://img.shields.io/github/license/Iterable/swift-sdk)](https://opensource.org/licenses/MIT)

**SmartNetwork** is a lightweight, developer-friendly networking library for Swift. It wraps `URLSession` in a clean and flexible API that’s fully compatible with Swift Concurrency. Whether you’re into `async/await` or prefer trusty closures, SmartNetwork helps you build robust, testable network layers—without all the boilerplate.

---

## ✨ Features

- Clean, strongly typed networking using `Decodable`.
- Supports both `async/await` and closure-based APIs.
- Built-in decoding for common response types:
  - `Void` — when you don’t expect data back.
  - `Data` — raw binary responses.
  - `Decodable` — your custom models.
  - `UIImage` — image fetching made easy.
  - `Any` — raw JSON as dictionaries or arrays.
- Custom decoding support with the `Deserializable` protocol.
- Decode deeply nested JSON with `keyPath`.
- Plugin system for logging, auth, request mutation, and more.
- Control request lifecycles via `SmartTask`.
- Built-in stubbing support for reliable, isolated tests.

---

## 🚀 Usage

### Async/Await

```swift
let result = await manager.decodable.request(TestInfo.self, address: address)
```

### Closures

```swift
manager.decodable.request(TestInfo.self, address: address) { result in
    // Handle result
}.start()
```

### Fluent API

```swift
let result = await manager.request(address: address).decodeAsync(TestInfo.self)
```

```swift
manager.request(address: address).decode(TestInfo.self).complete { result in
    // Handle result
}.detach().deferredStart()
```

---

## 🧩 Plugin System

SmartNetwork includes a flexible plugin system that lets you hook into and customize request/response behavior.

- `Plugins.StatusCode` – HTTP status code validation.
- `Plugins.Basic`, `Plugins.Bearer` – Auth strategies out of the box.
- `Plugins.TokenPlugin` – Modify headers or query parameters.
- `Plugins.Log`, `Plugins.LogOS` – Curl-style and OS logging.
- `Plugins.JSONHeaders` – Auto-inject JSON headers.
- `PluginPriority` – Control the order plugins execute in.
- `StopTheLine` – Temporarily halt all requests (e.g. to refresh tokens).

---

## 🔧 Custom Decoding

Need to decode deeply nested JSON? No problem.

```swift
protocol KeyPathDecodable {
    associatedtype Response: Decodable
    static var keyPath: [String] { get }
}

extension SmartRequestManager {
    func keyPathed<T: KeyPathDecodable>(_ type: T.Type = T.self) -> TypedRequestManager<T.Response?> {
        return custom(KeyPathDecodableContent<T>())
    }
}
```

---

## 🧪 Testing

SmartNetwork makes it easy to write fast, isolated unit tests with support for stubbing and mocking via `HTTPStubServer` and [`SpryKit`](https://github.com/NikSativa/SpryKit).

---

## 🖼️ Image Loading

Need to fetch and display images? Pair SmartNetwork with [`SmartImages`](https://github.com/NikSativa/SmartImages) for async image loading support.

---

## 📚 Documentation

- [SmartNetwork Overview (PDF)](./.instructions/SmartNetwork.pdf)  
  <img src="./.instructions/SmartNetwork.jpg" alt="SmartNetwork Overview Preview" width="300" />

- [Plugins Behavior (PDF)](./.instructions/Plugins_behavior.pdf)  
  <img src="./.instructions/Plugins_behavior.jpg" alt="Plugins Behavior Preview" width="300" />

---

## 📦 Installation

To add SmartNetwork to your project via Swift Package Manager:

```swift
.package(url: "https://github.com/NikSativa/SmartNetwork.git", from: "5.0.0")
```

Then include `"SmartNetwork"` as a dependency for your target.

---

## 📄 License

SmartNetwork is available under the MIT License.
