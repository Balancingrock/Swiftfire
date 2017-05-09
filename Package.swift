import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "https://github.com/Balancingrock/SwifterLog", Version(0, 10, 9)),
        .Package(url: "https://github.com/Balancingrock/SecureSockets", Version(0, 4, 7)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 2, 0))
    ]
)
