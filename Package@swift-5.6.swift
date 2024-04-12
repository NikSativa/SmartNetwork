// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "SmartNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SmartNetwork", targets: ["SmartNetwork"]),
        .library(name: "SmartNetworkTestHelpers", targets: ["SmartNetworkTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/SpryKit.git", .upToNextMajor(from: "2.2.2")),
        .package(url: "https://github.com/NikSativa/Threading.git", .upToNextMajor(from: "1.3.3"))
    ],
    targets: [
        .target(name: "SmartNetwork",
                dependencies: [
                    "Threading",
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "SmartNetworkTestHelpers",
                dependencies: [
                    "SmartNetwork",
                    "Threading",
                    .product(name: "ThreadingTestHelpers", package: "Threading"),
                    "SpryKit"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "SmartNetworkTests",
                    dependencies: [
                        "SmartNetwork",
                        "SmartNetworkTestHelpers",
                        "Threading",
                        .product(name: "ThreadingTestHelpers", package: "Threading"),
                        "SpryKit"
                    ],
                    path: "Tests",
                    resources: [
                        .copy("JSON/HTTPStubBody.json")
                    ])
    ]
)
