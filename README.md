# SmartNetwork
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FSmartNetwork%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/SmartNetwork)
[![CI](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/SmartNetwork/actions/workflows/swift_macos.yml)

Light weight wrapper around URLSession. 

## The main features are: 
- strong typed responses
> await manager.decodable.request(**TestInfo.self**, address: address)
- predefined API for basic types: *Void, Data, Image, Any(JSON)*
- *async/await* and *closure* strategies in one interface
- use `CustomDecodable` to define your own decoding strategy or type
- **Plugin** is like Android interceptors. Handle every *request-response* in runtime!
  + *Plugins.StatusCode* to handle http status codes or use *StatusCode* directly for easy mapping to human readable enumeration
  + *Plugins.Basic* or *Plugins.Bearer* for easy auth strategy
  + *Plugins.TokenPlugin* to update every request 
- **StopTheLine** mechanic to handle any case when you need to stop whole network and wait while you make something: *update auth token, handle Captcha etc..*
- **HTTPStubServer** mocks your own network in runtime. Make your magic while your server are not ready!
- macOS/iOS supports

### New structure of network request organization based on that new interface:
```
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
```
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
