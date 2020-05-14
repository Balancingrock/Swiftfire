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
        .package(url: "../../SwifterLog", from: "2.1.0"),
        .package(url: "../../SecureSockets", from: "1.1.0"),
        .package(url: "../../KeyedCache", from: "1.2.2"),
        .package(url: "../../BRBON", from: "1.3.0"),
        .package(url: "https://github.com/Balancingrock/Http", from: "1.2.1")
    ],
    targets: [
        .target(name: "Custom", dependencies: ["BRBON"]),
        .target(name: "Core", dependencies: ["SwifterLog", "COpenSsl", "KeyedCache", "SecureSockets", "BRBON", "Custom", "Http"]),
        .target(name: "Functions", dependencies: ["SwifterLog", "Http", "Custom", "Core", "COpenSsl", "Services"]),
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
