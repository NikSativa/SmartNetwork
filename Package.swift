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
        .library(name: "NRequestTestHelpers", targets: ["NRequestTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.3.4")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.1.17"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: [
                    "NQueue",
                ],
                path: "Source"),
        .target(name: "NRequestTestHelpers",
                dependencies: [
                    "NRequest",
                    "NQueue",
                    .product(name: "NQueueTestHelpers", package: "NQueue"),
                    "NSpry"
                ],
                path: "TestHelpers"),
        .testTarget(name: "NRequestTests",
                    dependencies: [
                        "NRequest",
                        "NRequestTestHelpers",
                        "NQueue",
                        .product(name: "NQueueTestHelpers", package: "NQueue"),
                        "NSpry"
                    ],
                    path: "Tests",
                    resources: [
                        .copy("JSON/HTTPStubBody.json")
                    ])
    ]
)
