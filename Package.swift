import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "https://github.com/Balancingrock/SwifterLog", Version(1, 1, 1)),
        .Package(url: "https://github.com/Balancingrock/SecureSockets", Version(0, 4, 11)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 6, 0)),
        .Package(url: "https://github.com/Balancingrock/BRBON", Version(0, 4, 2)),
        .Package(url: "https://github.com/Balancingrock/Http", Version(0, 0, 5)),
        .Package(url: "https://github.com/Balancingrock/Html", Version(0, 0, 2))
    ]
)
