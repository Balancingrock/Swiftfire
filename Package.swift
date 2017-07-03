import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "https://github.com/Balancingrock/SwifterLog", Version(0, 10, 12)),
        .Package(url: "https://github.com/Balancingrock/SecureSockets", Version(0, 4, 9)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 4, 0)),
        .Package(url: "https://github.com/Balancingrock/Http", Version(0, 0, 5)),
        .Package(url: "https://github.com/Balancingrock/Html", Version(0, 0, 2))
    ]
)
