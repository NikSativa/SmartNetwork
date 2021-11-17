// swift-tools-version:5.2

import PackageDescription

// swiftformat:disable all
let package = Package(
    name: "NRequest",
    platforms: [.iOS(.v12), .macOS(.v10_14)],
    products: [
        .library(name: "NRequest", targets: ["NRequest"]),
        .library(name: "NRequestTestHelpers", targets: ["NRequestTestHelpers"]),
        .library(name: "NRequestExtraTestHelpers", targets: ["NRequestExtraTestHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.2.1")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMajor(from: "1.1.4")),
        .package(url: "https://github.com/NikSativa/NCallback.git", .upToNextMajor(from: "2.9.3")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.1.8"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: ["NQueue",
                               "NCallback"],
                path: "Source"),
        .target(name: "NRequestTestHelpers",
                dependencies: ["NRequest",
                               "NQueue",
                               .product(name: "NQueueTestHelpers", package: "NQueue"),
                               "NSpry"],
                path: "TestHelpers/Core"),
        .target(name: "NRequestExtraTestHelpers",
                dependencies: ["NRequest",
                               "Nimble",
                               "NSpry"],
                path: "TestHelpers/Extra"),
        .testTarget(name: "NRequestTests",
                    dependencies: ["NCallback",
                                   .product(name: "NCallbackTestHelpers", package: "NCallback"),
                                   "NRequest",
                                   "NRequestTestHelpers",
                                   "NRequestExtraTestHelpers",
                                   "NQueue",
                                   .product(name: "NQueueTestHelpers", package: "NQueue"),
                                   "NSpry",
                                   .product(name: "NSpry_Nimble", package: "NSpry"),
                                   "Nimble",
                                   "Quick"],
                    path: "Tests")
    ],
    swiftLanguageVersions: [.v5]
)
