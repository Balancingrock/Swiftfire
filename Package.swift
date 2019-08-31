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
        .package(url: "https://github.com/Balancingrock/SwifterLog", from: "2.0.0"),
        .package(url: "https://github.com/Balancingrock/SecureSockets", from: "1.0.0"),
        .package(url: "https://github.com/Balancingrock/KeyedCache", from: "1.1.0"),
        .package(url: "https://github.com/Balancingrock/BRBON", from: "1.0.0"),
        .package(url: "https://github.com/Balancingrock/Http", from: "1.0.0"),
        .package(url: "https://github.com/Balancingrock/Html", from: "1.0.0")
    ],
    targets: [
        .target(name: "Custom", dependencies: ["BRBON"]),
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
