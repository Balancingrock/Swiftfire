import PackageDescription

let package = Package(
    name: "Swiftfire",
    dependencies: [
        .Package(url: "../SwiftfireCore", Version(0,  1,  0))
    ]
)