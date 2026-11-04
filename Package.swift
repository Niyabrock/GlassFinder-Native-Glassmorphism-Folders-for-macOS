// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [.library(name: "GlassFinderCore", targets: ["GlassFinderCore"])]
var targets: [Target] = [
    .target(name: "GlassFinderCore"),
    .testTarget(name: "GlassFinderCoreTests", dependencies: ["GlassFinderCore"])
]
#if os(macOS)
products.append(.executable(name: "GlassFinder", targets: ["GlassFinder"]))
targets.append(.executableTarget(name: "GlassFinder", dependencies: ["GlassFinderCore"], resources: [.process("Resources")]))
#endif

let package = Package(
    name: "GlassFolder",
    platforms: [.macOS("14.5")],
    products: products,
    targets: targets
)
