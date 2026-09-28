// swift-tools-version: 5.9
// Builds a client from ../../openapi.json with swift-openapi-generator to prove
// the committed contract is consumable (contract/scripts/check-generators.sh).
import PackageDescription

let package = Package(
    name: "MurmursAPIConsumerCheck",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MurmursAPI",
            dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
    ]
)
