// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ClipViewApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipView", targets: ["ClipViewApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClipViewApp",
            dependencies: [],
            path: "Sources/ClipViewApp"
        ),
        .testTarget(
            name: "ClipViewAppTests",
            dependencies: ["ClipViewApp"]
        )
    ]
)
