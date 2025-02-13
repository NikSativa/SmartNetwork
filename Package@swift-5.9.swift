// swift-tools-version:5.9
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "SmartNetwork",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v13),
        .visionOS(.v1),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "SmartNetwork", targets: ["SmartNetwork"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMinor(from: "3.0.2")),
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMinor(from: "2.1.1"))
    ],
    targets: [
        .target(name: "SmartNetwork",
                dependencies: [
                    "Threading",
                ],
                path: "Source",
                resources: [
                    .process("PrivacyInfo.xcprivacy")
                ],
                swiftSettings: [
                    .define("supportsVisionOS", .when(platforms: [.visionOS])),
                ]),
        .testTarget(name: "SmartNetworkTests",
                    dependencies: [
                        "SmartNetwork",
                        "Threading",
                        "SpryKit"
                    ],
                    path: "Tests",
                    resources: [
                        .copy("JSON/HTTPStubBody.json")
                    ],
                    swiftSettings: [
                        .define("supportsVisionOS", .when(platforms: [.visionOS])),
                    ])
    ]
)
