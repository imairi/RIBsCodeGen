// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RIBsCodeGen",
    products: [
        .executable(name: "ribscodegen", targets: ["RIBsCodeGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.31.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.2.0")
    ],
    targets: [
        .target(
            name: "RIBsCodeGen", 
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                "PathKit",
                "Rainbow"]
        )
    ]
)
