# SmartNetwork
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![CI](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml)

Light weight wrapper around URLSession. 

## The main features are: 
- strong typed responses based on Decodable protocol
  - async/await
  > await manager.decodable.request(**TestInfo.self**, address: address)
  - closure strategies
  > let req = manager.decodable.request(**TestInfo.self**, address: address) { result in ... }

- predefined API for basic types: *Void, Data, Image, Any(JSON)*
- *async/await* and *closure* strategies in one interface
- use `CustomDecodable` to define your own decoding strategy or type
- **Plugin** is like Android interceptors. Handle every *request-response* in runtime! Make your own magic with validation, logging, auth, etc...
  + *Plugins.StatusCode* to handle http status codes or use *StatusCode* directly for easy mapping to human readable enumeration
  + *Plugins.Basic* or *Plugins.Bearer* for easy use auth strategy
  + *Plugins.TokenPlugin* to update every request headers or query parameters
  + *Plugins.Curl* to print every request in curl format
  + *Plugins.JSONHeaders* to add json specific headers to every request
- **PluginPriority** to define order of plugins in chain of execution 
- **StopTheLine** mechanic to handle any case when you need to stop whole network and wait while you make something: *update auth token, handle Captcha etc..*
- **HTTPStubServer** mocks your own network in runtime. Make your magic while your server are not ready!
- **SmartTask** for managing the lifecycle of network requests. Cancel the task deinitiation request or handle the detached task manually - everything is under control!
- Easily complements [SmartImage](https://github.com/NikSativa/SmartImages) for image loading.


### New structure of network request organization based on that new interface:

```swift
public protocol RequestManagering {
    // MARK: -

    var pure: PureRequestManager { get }
    var decodable: DecodableRequestManager { get }
    var void: TypedRequestManager<Void> { get }

    // MARK: - strong

    var data: TypedRequestManager<Data> { get }
    var image: TypedRequestManager<Image> { get }
    var json: TypedRequestManager<Any> { get }

    // MARK: - optional

    var dataOptional: TypedRequestManager<Data?> { get }
    var imageOptional: TypedRequestManager<Image?> { get }
    var jsonOptional: TypedRequestManager<Any?> { get }

    // MARK: - custom

    func custom<T: CustomDecodable>(_ type: T.Type) -> TypedRequestManager<T.Object>
}
```

### New usage of API with short autocompletion:

```swift
Task {
    let manager = RequestManager.create()
    let result = await manager.decodable.request(TestInfo.self, address: address)
    switch result {
    case .success(let obj):
        // do something with response
    case .failure(let error):
        // do something with error
    }
}
```

## Custom request manager

Customize your own network with your own custom decodable type:

```swift
/// Custom decodable protocol for decoding data from response with specified keyPath
protocol KeyPathDecodable<Response> {
    associatedtype Response: Decodable
    static var keyPath: [String] { get }
}

extension RequestManagering {
    func keyPathed<T: KeyPathDecodable>(_ type: T.Type = T.self) -> TypedRequestManager<T.Response?> {
        return custom(KeyPathDecodableContent<T>.self)
    }
}

private struct KeyPathDecodableContent<T: KeyPathDecodable>: CustomDecodable {
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<T.Response?, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            do {
                let obj = try data.decode(T.Response.self, keyPath: T.keyPath, decoder: decoder())
                return .success(obj)
            } catch {
                return .failure(error)
            }
        } else {
            return .success(nil)
        }
    }
}
```
