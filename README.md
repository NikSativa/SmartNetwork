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
  - `UIImage` (or `NSImage`) — image fetching made easy.
  - `Any` — raw JSON as dictionaries or arrays.
- Custom decoding support with the `Deserializable` protocol.
- Decode deeply nested JSON with `keyPath`.
- Plugin system for logging, auth, request mutation, and more.
- Control request lifecycles via `SmartTask`.
- Built-in stubbing support for reliable, isolated tests.

---

## 🚀 Usage

SmartNetwork offers multiple styles for making requests, allowing you to choose what best fits your coding style or project needs.

### 🔹 Async/await

Perform a request using Swift's modern concurrency syntax:

```swift
let result = await manager.decodable.request(TestInfo.self, address: address)
```

### 🔹 Closure-based

Use completion handlers for backward compatibility or callback-driven workflows:

```swift
manager.decodable.request(TestInfo.self, address: address) { result in
    // Handle result here
}.start()
```

### 🔹 Fluent chainable API

Construct readable, chainable network calls using SmartNetwork’s fluent API:

```swift
let result = await manager.request(address: address).decodeAsync(TestInfo.self)
```

```swift
manager.request(address: address)
    .decode(TestInfo.self)
    .complete { result in
        // Handle result here
    }
    .detach()
    .deferredStart()
```

These patterns offer flexibility whether you're building simple calls or need more granular control over the request lifecycle.

---

## 🧩 Plugin system

SmartNetwork includes a modular plugin system that allows you to customize and extend networking behavior without changing core logic. Plugins can be used to modify requests, inspect responses, or enforce specific policies.

Here are some built-in plugins you can use:

- `Plugins.StatusCode` – Validates HTTP status codes and can trigger custom error handling.
- `Plugins.Basic`, `Plugins.Bearer` – Easily apply Basic or Bearer authentication headers.
- `Plugins.TokenPlugin` – Inject custom tokens via headers or query parameters.
- `Plugins.Log`, `Plugins.LogOS` – Output curl-style debug logs or use system logging.
- `Plugins.JSONHeaders` – Automatically adds `Content-Type` and `Accept` headers for JSON APIs.
- `PluginPriority` – Define the order in which plugins execute.
- `StopTheLine` – Temporarily blocks all requests (e.g. during token refresh or maintenance).

You can combine and prioritize plugins to precisely control the behavior of your networking pipeline.

---

## 🔧 Custom decoding

You can define types that include a decoding key path for nested JSON parsing:

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

## 🖼️ Image loading

Need to fetch and display images? Pair SmartNetwork with [`SmartImages`](https://github.com/NikSativa/SmartImages) for async image loading support.

---

## 📚 Documentation

<a id="architecture-overview"></a>
### Architecture Overview

SmartNetwork follows a modular architecture with a clear request lifecycle:

```mermaid
graph TB
    subgraph Manager["SmartRequestManager"]
        Plugins["Plugins System"]
        StopTheLine["StopTheLine Mechanism"]
        Retrier["Retrier Logic"]
    end
    
    Start([Request Created]) --> Prepare[Plugin: prepare]
    Prepare --> WillSend[Plugin: willSend]
    WillSend --> Network[Network Request<br/>SmartURLSession → URLSession]
    Network --> DidReceive[Plugin: didReceive]
    DidReceive --> StopTheLineCheck{StopTheLine<br/>Verification}
    StopTheLineCheck -->|Pass| Verify[Plugin: verify]
    StopTheLineCheck -->|Retry| WillSend
    StopTheLineCheck -->|Replace| Verify
    Verify --> DidFinish[Plugin: didFinish]
    DidFinish --> Decode[Response Decoding<br/>Decodable/Data/Image/JSON/Void]
    Decode --> RetryCheck{Retrier<br/>Evaluation}
    RetryCheck -->|Retry| WillSend
    RetryCheck -->|Complete| End([Completion<br/>Result or Handler])
    
    Manager -.-> Prepare
    Manager -.-> StopTheLineCheck
    Manager -.-> RetryCheck
```

<a id="plugin-system-lifecycle"></a>
### Plugin System Lifecycle

Plugins execute at specific points in the request lifecycle, allowing you to intercept and modify requests/responses:

```mermaid
sequenceDiagram
    participant Client
    participant Manager as SmartRequestManager
    participant Plugins as Plugin System
    participant StopTheLine as StopTheLine
    participant Network as URLSession
    participant Decoder as Response Decoder
    
    Client->>Manager: Create Request
    Manager->>Plugins: prepare() [Async]
    Plugins-->>Manager: Modified Request
    Manager->>Plugins: willSend()
    Plugins-->>Manager: Request Validated
    Manager->>Network: Execute HTTP Request
    Network-->>Manager: Raw Response
    Manager->>Plugins: didReceive()
    Plugins-->>Manager: Response Processed
    Manager->>StopTheLine: verify()
    alt Pass
        StopTheLine-->>Manager: .pass
    else Retry
        StopTheLine-->>Manager: .retry
        Manager->>Plugins: willSend() [Retry]
    else Replace
        StopTheLine-->>Manager: .replace
    end
    Manager->>Plugins: verify() [Throws on failure]
    Plugins-->>Manager: Validation Result
    Manager->>Plugins: didFinish()
    Plugins-->>Manager: Cleanup Complete
    Manager->>Decoder: Decode Response
    Decoder-->>Manager: Typed Result
    Manager-->>Client: Return Result<T>
```

### Component Structure

```mermaid
graph TD
    SN[SmartNetwork]
    
    SN --> Core[Core Components]
    Core --> SRM[SmartRequestManager<br/>Main Orchestrator]
    Core --> SR[SmartRequest<br/>Lifecycle Handler]
    Core --> SResp[SmartResponse<br/>Response Wrapper]
    Core --> SUS[SmartURLSession<br/>URLSession Abstraction]
    
    SN --> Request[Request Building]
    Request --> Addr[Address<br/>URL Construction]
    Request --> Params[Parameters<br/>Request Config]
    Request --> UI[UserInfo<br/>Metadata]
    
    SN --> PluginSys[Plugin System]
    PluginSys --> Plugin[Plugin Protocol]
    PluginSys --> Priority[PluginPriority<br/>Execution Order]
    PluginSys --> BuiltIn[Built-in Plugins]
    BuiltIn --> Basic[Plugins.Basic<br/>Basic Auth]
    BuiltIn --> Bearer[Plugins.Bearer<br/>Bearer Token]
    BuiltIn --> Token[Plugins.TokenPlugin<br/>Custom Tokens]
    BuiltIn --> Status[Plugins.StatusCode<br/>Status Validation]
    BuiltIn --> Log[Plugins.Log<br/>cURL Logging]
    BuiltIn --> LogOS[Plugins.LogOS<br/>System Logging]
    BuiltIn --> JSON[Plugins.JSONHeaders<br/>JSON Headers]
    
    SN --> Response[Response Handling]
    Response --> Content[Content Types]
    Content --> Decodable[DecodableContent<br/>Decodable]
    Content --> Data[DataContent<br/>Raw Data]
    Content --> Image[ImageContent<br/>UIImage/NSImage]
    Content --> JSONContent[JSONContent<br/>Any Dictionary/Array]
    Content --> Void[VoidContent<br/>No Body]
    Response --> KeyPath[DecodeByKeyPath<br/>Nested JSON]
    
    SN --> Advanced[Advanced Features]
    Advanced --> STL[StopTheLine<br/>Flow Control]
    Advanced --> Retrier[SmartRetrier<br/>Retry Logic]
    Advanced --> Task[SmartTask<br/>Cancellation]
    Advanced --> Stub[HTTPStubServer<br/>Testing]
    
    SN --> Managers[Request Managers]
    Managers --> RM[RequestManager<br/>Base Protocol]
    Managers --> TRM[TypedRequestManager<br/>Type-safe]
    Managers --> DRM[DecodableRequestManager<br/>Decodable-specific]
```

### Request Manager Types

SmartNetwork provides multiple request manager interfaces for different use cases:

| Manager Type | Purpose | Example |
|-------------|---------|---------|
| `RequestManager` | Base protocol for raw requests | `manager.request(address:params:userInfo:)` |
| `TypedRequestManager<T>` | Type-safe requests with generic response | `manager.decodable.request(Model.self, address:)` |
| `DecodableRequestManager` | Specialized for `Decodable` types | `manager.decodable.request(User.self, address:)` |

### Built-in Plugins Reference

| Plugin | Priority | Purpose |
|--------|----------|---------|
| `Plugins.Basic` | Configurable | Adds Basic Authentication header |
| `Plugins.Bearer` | Configurable | Adds Bearer token authentication |
| `Plugins.TokenPlugin` | Configurable | Injects custom tokens (header/query) |
| `Plugins.StatusCode` | Configurable | Validates HTTP status codes |
| `Plugins.Log` | Configurable | Logs requests as cURL commands |
| `Plugins.LogOS` | Configurable | Logs using OSLog/system logging |
| `Plugins.JSONHeaders` | Configurable | Adds JSON Content-Type headers |

---

## 📦 Installation

To add SmartNetwork to your project via Swift Package Manager:

```swift
.package(url: "https://github.com/NikSativa/SmartNetwork.git", from: "5.0.0")
```

Then, add `"SmartNetwork"` to your target dependencies.

---

## 📄 License

`SmartNetwork` is available under the MIT License.
