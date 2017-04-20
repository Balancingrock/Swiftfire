import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "../SwiftfireCore", Version(0, 10, 6)),
        .Package(url: "../KeyedCache", Version(0, 2, 0))
    ]
)
