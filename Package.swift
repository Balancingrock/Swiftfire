import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "../SwiftfireCore", Version(0,  10,  0)),
        .Package(url: "https://github.com/Balancingrock/KeyedCache", Version(0, 1, 0))
    ]
)
