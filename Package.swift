// swift-tools-version:5.3

import PackageDescription

let commonTestDependencies: [PackageDescription.Target.Dependency] = [
    "Spry",
    "Nimble",
    "Quick",
    .product(name: "Spry_Nimble", package: "Spry")
]

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
        .package(url: "https://github.com/NikSativa/Spry.git", .upToNextMajor(from: "3.4.3")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.1.2")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
        .package(url: "https://github.com/NikSativa/NInject.git", .upToNextMajor(from: "1.3.3")),
        .package(url: "https://github.com/NikSativa/NCallback.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "NRequest",
                dependencies: ["NQueue", "NCallback"],
                path: "Source/Core"),
        .target(name: "NRequestTestHelpers",
                dependencies: [
                    "NRequest",
                    "NQueue",
                    .product(name: "NQueueTestHelpers", package: "NQueue"),
                    "Nimble",
                    "Spry"
                ],
                path: "TestHelpers"),
        .testTarget(name: "NRequestTests",
                    dependencies: [
                        "NCallback",
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        "NInject",
                        .product(name: "NInjectTestHelpers", package: "NInject"),
                        "NRequest",
                        "NRequestTestHelpers",
                        "NQueue",
                        .product(name: "NQueueTestHelpers", package: "NQueue")
                    ] + commonTestDependencies,
                    path: "Tests/Specs/Core"
        ),

        .target(name: "NRequest_Inject",
                dependencies: ["NCallback", "NRequest"],
                path: "Source/Inject"),
        .testTarget(name: "NRequest_InjectTests",
                    dependencies: [
                        .product(name: "NCallbackTestHelpers", package: "NCallback"),
                        .product(name: "NInjectTestHelpers", package: "NInject"),
                        "NInject",
                        "NRequest",
                        "NRequest_Inject",
                        "NRequestTestHelpers",
                        "NQueue",
                        .product(name: "NQueueTestHelpers", package: "NQueue")
                    ] + commonTestDependencies,
                    path: "Tests/Specs/Inject"
        )
    ],
    swiftLanguageVersions: [.v5]
)
