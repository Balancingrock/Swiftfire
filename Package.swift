import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "../SwiftfireCore", Version(0, 10, 7)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 2, 0))
    ]
)
