// swift-tools-version: 5.9
// Murmurs API client, generated from contract/openapi.json by the
// swift-openapi-generator build plugin (adr/0010). Also built on its own by
// contract/scripts/check-generators.sh to prove the contract is consumable.
import PackageDescription

let package = Package(
    name: "MurmursAPI",
    platforms: [.iOS("18.0"), .macOS(.v14)],
    products: [
        .library(name: "MurmursAPI", targets: ["MurmursAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MurmursAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
    ]
)
