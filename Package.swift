// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Swiftfire",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "Swiftfire", targets: ["Swiftfire"])
    ],
    dependencies: [
        .package(url: "https://github.com/Balancingrock/SwifterLog", from: "1.7.0"),
        .package(url: "https://github.com/Balancingrock/SecureSockets", from: "0.7.3"),
        .package(url: "https://github.com/Balancingrock/KeyedCache", from: "0.8.0"),
        .package(url: "https://github.com/Balancingrock/BRBON", from: "0.8.0"),
        .package(url: "https://github.com/Balancingrock/Http", from: "0.2.1"),
        .package(url: "https://github.com/Balancingrock/Html", from: "0.1.0")
    ],
    targets: [
        .target(name: "Custom"),
        .target(name: "Core", dependencies: ["SwifterLog", "COpenSsl", "KeyedCache", "SecureSockets", "BRBON", "Custom", "Html", "Http"]),
        .target(name: "Functions", dependencies: ["SwifterLog", "Http", "Custom", "Core", "COpenSsl"]),
        .target(name: "Services", dependencies: ["SwifterLog", "Http", "Custom", "Core"]),
        .target(name: "Admin", dependencies: ["Core", "COpenSsl", "Functions", "Services"]),
        .target(
            name: "Swiftfire",
            dependencies: ["SwifterLog", "Admin", "Core", "Functions", "Services", "Custom"],
            linkerSettings: [
                .linkedLibrary("ssl"),
                .linkedLibrary("crypto"),
            ]
        )
    ]
)
