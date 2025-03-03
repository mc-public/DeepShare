## DeepShare
![](https://img.shields.io/badge/Platform-iOS_18.0+-blue)
![](https://img.shields.io/badge/LifeCycle-SwiftUI_6.0-yellow)
![](https://img.shields.io/badge/Swift_6.0-red)
### Description

**DeepShare** is a lightweight iOS application designed to process AI-generated Markdown text and perform advanced document transformations, including:

- Converting to long-form images
- Splitting into short-form image sequences
- Exporting as PDF documents
- Format conversion to .docx
- Cross-platform markup generation (LaTeX, HTML, etc.)

**DeepShare** has been listed on the App Store, and you can find the specific information about this app at the following link.

<a href="https://apps.apple.com/us/app/deepshare/id6742375235" target="_blank"><img width="150" alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"/></a>

### About The Repository

This source contains all the source code and build resources for DeepShare. 

The method to build this library is as follows. 

1. Clone this repository using `git clone https://github.com/mc-public/DeepShare.git`.
2. Open `ChatShare.xcodeproj` with Xcode.
3. Resign this project with your Apple developer account.
4. Press `Command+R` to build and run.

### Technologies

**DeepShare** is entirely written in Swift 6 and built on the `SwiftUI` lifecycle. 

- **(Markdown to TeX)** DeepShare utilizes the WebAssembly technology stack alongside [**Pandoc**](https://github.com/tweag/pandoc-wasm.git) to convert Markdown texts into formats like `docx` and `tex`. 

- **(TeX to PDF)** DeepShare internally employs a streamlined XeTeX engine (compiled into WebAssembly, based on [**SwiftLaTeX**](https://github.com/SwiftLaTeX/SwiftLaTeX.git) package) and a minimal LaTeX compilation package to convert TeX files into PDF files for paginating Markdown documents.

[**SwiftUIIntrospect**](https://github.com/siteline/swiftui-introspect.git) helps us achieve many things that are impossible in pure SwiftUI.

### License

Considering the license restrictions of [**Pandoc**](https://github.com/jgm/pandoc.git), [**SwiftLaTeX**](https://github.com/SwiftLaTeX/SwiftLaTeX.git) and [**texlive-source**](https://github.com/TeX-Live/texlive-source.git), this tool is open-sourced under the AGPL-3.0 license. 

Additionally, this tool uses some graphic resource files with third-party copyrights, for which DeepShare has obtained legal usage rights. Please be mindful of potential copyright issues when using these resources.
