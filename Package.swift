// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "RIBsCodeGen",
    products: [
        .executable(name: "RIBsCodeGen", targets: ["RIBsCodeGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.22.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "0.9.2"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "RIBsCodeGen", 
            dependencies: ["SourceKittenFramework", "PathKit", "Rainbow"]
        )
    ]
)
