// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RIBsCodeGen",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ribscodegen", targets: ["RIBsCodeGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.37.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.2.0")
    ],
    targets: [
        .executableTarget(
            name: "RIBsCodeGen", 
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                "PathKit",
                "Rainbow"]
        )
    ]
)
