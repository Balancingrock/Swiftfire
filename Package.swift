// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Swiftfire",
    products: [
        .executable(name: "Swiftfire", targets: ["Swiftfire"])
    ],
    dependencies: [
        .package(url: "https://github.com/Balancingrock/SwifterLog", from: "2.2.1"),
        .package(url: "https://github.com/Balancingrock/SecureSockets", from: "1.1.3"),
        .package(url: "https://github.com/Balancingrock/KeyedCache", from: "1.2.2"),
        .package(url: "https://github.com/Balancingrock/BRBON", from: "1.3.0"),
        .package(url: "https://github.com/Balancingrock/Http", from: "1.2.1")
    ],
    targets: [
        .target(name: "Custom", dependencies: ["BRBON"]),
        .target(name: "Core", dependencies: ["SwifterLog", "Copenssl", "KeyedCache", "SecureSockets", "BRBON", "Custom", "Http"]),
        .target(name: "Functions", dependencies: ["SwifterLog", "Http", "Custom", "Core", "Copenssl", "Services"]),
        .target(name: "Services", dependencies: ["SwifterLog", "Http", "Custom", "Core"]),
        .target(name: "Admin", dependencies: ["Core", "Copenssl", "Functions", "Services"]),
        .target(name: "Swiftfire", dependencies: ["SwifterLog", "Admin", "Core", "Functions", "Services", "Custom"]
        )
    ]
)
