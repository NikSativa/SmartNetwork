// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "NRequest",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "NRequest", targets: ["NRequest"]),
        .library(name: "NRequest_Inject", targets: ["NRequest_Inject"]),
        .library(name: "NRequestTestHelpers", targets: ["NRequestTestHelpers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/Spry.git", .upToNextMajor(from: "3.3.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
        .package(url: "https://github.com/NikSativa/NInject.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/NikSativa/NCallback.git", .upToNextMajor(from: "1.2.0"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: ["NCallback"],
                path: "Source/Core"),
        .target(name: "NRequestTestHelpers",
                dependencies: [
                    "NRequest",
                    "Nimble",
                    "Spry"
                ],
                path: "TestHelpers"),
        .testTarget(name: "NRequestTests",
                    dependencies: [
                        "Spry",
                        "Nimble",
                        "Quick",
                        .product(name: "Spry_Nimble", package: "Spry"),
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        .product(name: "NInjectTestHelpers", package: "NInject"),
                        "NInject",
                        "NRequest",
                        "NRequestTestHelpers"
                    ],
                    path: "Tests/Specs/Core"
        ),

        .target(name: "NRequest_Inject",
                dependencies: ["NCallback", "NRequest"],
                path: "Source/Inject"),
        .testTarget(name: "NRequest_InjectTests",
                    dependencies: [
                        "Spry",
                        "Nimble",
                        "Quick",
                        .product(name: "Spry_Nimble", package: "Spry"),
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        .product(name: "NInjectTestHelpers", package: "NInject"),
                        "NInject",
                        "NRequest",
                        "NRequest_Inject",
                        "NRequestTestHelpers"
                    ],
                    path: "Tests/Specs/Inject"
        )
    ],
    swiftLanguageVersions: [.v5]
)
