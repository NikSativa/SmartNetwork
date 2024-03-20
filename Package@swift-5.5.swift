// swift-tools-version:5.5
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NRequest",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NRequest", targets: ["NRequest"]),
        .library(name: "NRequestTestHelpers", targets: ["NRequestTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "2.1.4")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.2.4"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: [
                    "NQueue",
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .target(name: "NRequestTestHelpers",
                dependencies: [
                    "NRequest",
                    "NQueue",
                    .product(name: "NQueueTestHelpers", package: "NQueue"),
                    "NSpry"
                ],
                path: "TestHelpers",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
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
