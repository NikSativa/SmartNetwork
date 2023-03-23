// swift-tools-version:5.6
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NRequest",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "NRequest", targets: ["NRequest"]),
        .library(name: "NRequestTestHelpers", targets: ["NRequestTestHelpers"]),
        .library(name: "NRequestExtraTestHelpers", targets: ["NRequestExtraTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "6.1.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "11.2.1")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.3.3")),
        .package(url: "https://github.com/NikSativa/NCallback.git", .upToNextMajor(from: "2.10.17")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.1.17"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: [
                    "NQueue",
//                    "NCallback"
                ],
                path: "Source",
                exclude: ["Callback"]),
        .target(name: "NRequestTestHelpers",
                dependencies: [
                    "NRequest",
                    "NQueue",
                    .product(name: "NQueueTestHelpers", package: "NQueue"),
                    "NSpry"
                ],
                path: "TestHelpers/Core"),
        .target(name: "NRequestExtraTestHelpers",
                dependencies: [
                    "NRequestTestHelpers",
                    "NRequest",
                    "Nimble",
                    "NSpry"
                ],
                path: "TestHelpers/Nimble"),
        .testTarget(name: "NRequestTests",
                    dependencies: [
                        "NCallback",
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        "NRequest",
                        "NRequestTestHelpers",
                        "NRequestExtraTestHelpers",
                        "NQueue",
                        .product(name: "NQueueTestHelpers", package: "NQueue"),
                        "NSpry",
                        .product(name: "NSpry_Nimble", package: "NSpry"),
                        "Nimble",
                        "Quick"
                    ],
                    path: "Tests")
    ]
)
