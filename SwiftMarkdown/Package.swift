// swift-tools-version: 6.0

import PackageDescription

let webResources: [Resource] = ["concise", "github", "blood", "boundless_left", "tree", "succinct_cyan"].map { Resource.copy("Resources/stylesheets/\($0).css") }

+ [
    "fa-regular-400.woff2",
    "fa-solid-900.woff2",
    "KaTeX_Main-Bold.woff2",
    "KaTeX_Main-Regular.woff2",
    "KaTeX_Math-Italic.woff2",
    "KaTeX_Size2-Regular.woff2",
    "all.min.css",
    "github-markdown.min.css",
    "katex.min.css",
    "texmath.min.css",
    "clipboard.min.js",
    "katex.min.js",
    "markdown-it-footnote.min.js",
    "markdown-it-sub.min.js",
    "markdown-it-sup.min.js",
    "morphdom.min.js",
    "texmath.min.js"
].map { Resource.copy("Resources/library/\($0)") }

let package = Package(
    name: "SwiftMarkdown",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "MarkdownView",
            targets: ["MarkdownView"]
        ),
    ],
    targets: [
        .target(
            name: "MarkdownView",
            resources: [.copy("Resources/template.html"),
                        .copy("Resources/script"),
                        .copy("Resources/stylesheets/default-macOS"),
                        .copy("Resources/stylesheets/default-iOS")] + webResources
        ),
    ],
    swiftLanguageModes: [.v6]
)
