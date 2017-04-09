import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "https://github.com/Balancingrock/SwiftfireCore", Version(0,  10,  4)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 1, 0))
    ]
)
