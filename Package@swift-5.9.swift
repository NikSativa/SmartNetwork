// swift-tools-version:5.9
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "SmartNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .visionOS(.v1),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SmartNetwork", targets: ["SmartNetwork"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMajor(from: "2.0.0"))
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