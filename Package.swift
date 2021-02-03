// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "RIBshokunin",
    products: [
        .executable(name: "RIBshokunin", targets: ["RIBshokunin"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.22.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "0.9.2"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "RIBshokunin", 
            dependencies: ["SourceKittenFramework", "PathKit", "Rainbow"]
        )
    ]
)
