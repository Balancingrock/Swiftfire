// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Swiftfire",
    products: [
        .executable(name: "Swiftfire", targets: ["Swiftfire"])
    ],
    dependencies: [
        .package(url: "https://github.com/Balancingrock/SwifterLog", from: "1.7.0"),
        .package(url: "https://github.com/Balancingrock/SecureSockets", from: "0.6.0"),
        .package(url: "https://github.com/Balancingrock/KeyedCache", from: "0.8.0"),
        .package(url: "https://github.com/Balancingrock/BRBON", from: "0.8.0"),
        .package(url: "https://github.com/Balancingrock/Http", from: "0.2.1"),
        .package(url: "https://github.com/Balancingrock/Html", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Swiftfire",
            dependencies: ["SwifterLog", "SecureSockets", "KeyedCache", "BRBON", "Http", "Html"]
        )
    ]
)
