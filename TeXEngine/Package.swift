// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "TeXEngine",
    platforms: [.iOS("17.0")],
    products: [
        .library(
            name: "TeXEngine",
            targets: ["TeXEngine"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TeXEngine",
            dependencies: [],
            exclude: [
                "Resources/pdftex/",
                "Resources/xetex/",
                "Resources/wasm/",
                "Resources/pdfTeXMake",
                "Resources/XeTeXMake",
            ],
            resources: [
                /* xetex engine files */
                .copy("Resources/xetex.js"),
                .copy("Resources/xetex.wasm"),
                .copy("Resources/XeTeXEngine.html"),
                .copy("Resources/xelatex.fmt"),
                /* pdftex engine files */
                .copy("Resources/pdftex.js"),
                .copy("Resources/pdftex.wasm"),
                .copy("Resources/pdfTeXEngine.html"),
                .copy("Resources/pdflatex.fmt"),
                /* log parser files */
                .copy("Resources/logParser/LogParser.js"),
                .copy("Resources/logParser/LogParserTest_error.log"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
