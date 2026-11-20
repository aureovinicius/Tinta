// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tinta",
    defaultLocalization: "pt-BR",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Tinta", targets: ["Tinta"])
    ],
    targets: [
        .executableTarget(
            name: "Tinta",
            path: "Sources/Tinta"
        ),
        .testTarget(
            name: "TintaTests",
            dependencies: ["Tinta"],
            path: "Tests/TintaTests",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-load-resolved-plugin",
                    "-Xfrontend", "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib##TestingMacros"
                ])
            ]
        )
    ]
)
