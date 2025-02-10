//
//  MarkdownView+WebView.swift
//  SwiftMarkdown
//
//  Created by 孟超 on 2025/2/9.
//

import WebKit

#if os(macOS)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

#if !os(visionOS)

@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView {
    /// The internal `WKWebView` for displaying the markdown content.
    public class WebView: WKWebView {
        
        /// The content height of current non-scrollable view.
        var contentHeight: CGFloat = 0
        /// The natural size for the receiving view, considering only properties of the view itself.
        override public var intrinsicContentSize: CGSize {
            .init(width: super.intrinsicContentSize.width, height: contentHeight)
        }
        
        nonisolated var isRenderingContent: Bool {
            get { lock.withLock { unsafe_isRenderingContent } }
            set { lock.withLock { unsafe_isRenderingContent = newValue } }
        }
        nonisolated(unsafe) var unsafe_isRenderingContent: Bool = false
        nonisolated private let lock = NSLock()
        
        /// Disables scrolling.
        #if os(macOS)
            override public func scrollWheel(with event: NSEvent) {
                super.scrollWheel(with: event)
                nextResponder?.scrollWheel(with: event)
            }
        #endif

        /// Removes "Reload" from the context menu.
        #if os(macOS)
            override public func willOpenMenu(_ menu: NSMenu, with _: NSEvent) {
                menu.items.removeAll { $0.identifier == .init("WKMenuItemIdentifierReload") }
            }
        #endif

        #if os(macOS)
            override public func keyDown(with event: NSEvent) {
                nextResponder?.keyDown(with: event)
            }

            override public func keyUp(with event: NSEvent) {
                nextResponder?.keyUp(with: event)
            }

            override public func flagsChanged(with event: NSEvent) {
                nextResponder?.flagsChanged(with: event)
            }

        #elseif os(iOS)
            override public func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesBegan(presses, with: event)
                next?.pressesBegan(presses, with: event)
            }

            override public func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesEnded(presses, with: event)
                next?.pressesEnded(presses, with: event)
            }

            override public func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesChanged(presses, with: event)
                next?.pressesChanged(presses, with: event)
            }
        #endif
    }
}

@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView.WebView {
    /// Update markdown text in the webview.
    func updateMarkdownContent(_ markdownContent: String) async {
        self.isRenderingContent = true
        Task.detached {
            let patternLeft = "(?<!\\n\\n)\\\\\\["
            let patternRight = "\\\\\\](?!\\n\\n)"
            let formatedString = markdownContent
                .replacingOccurrences(of: patternLeft, with: "\n\n\\\\[", options: .regularExpression)
                .replacingOccurrences(of: patternRight, with: "\\\\]\n\n")
            guard let markdownContentBase64Encoded = formatedString.data(using: .utf8)?.base64EncodedString() else { return }
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.async {
                    self.evaluateJavaScript("window.updateWithMarkdownContentBase64Encoded(`\(markdownContentBase64Encoded)`);0") { _,_  in
                        self.isRenderingContent = false
                        cont.resume()
                    }
                }
            }
        }
    }
    
    func updateFontSize(_ size: CGFloat) async {
        try? await self.evaluateJavaScript("document.getElementById('markdown-rendered').style.fontSize = '\(size)pt'")
    }
    
    func updateHorizontalPadding(_ length: Int) async {
        try! await self.evaluateJavaScript(
"""
document.getElementById('markdown-rendered').style.paddingLeft = '\(length)pt';
document.getElementById('markdown-rendered').style.paddingRight = '\(length)pt';
"""
        )
    }
    
    @available(macOS 14.0, iOS 17.0, *)
    func updateTheme(for theme: MarkdownView.Theme) async {
        try! await self.evaluateJavaScript(
"""
try {  document.body.removeChild(window.md_style)  } catch {};
window.md_style = document.createElement('style');
window.md_style.type = 'text/css';
window.md_style.innerHTML = `
\(theme.styleContent)
`
document.body.appendChild(window.md_style);
1;
"""
        )
    }
    
    
}

@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView {
    
    /// The Markdown rendered theme about the `MarkdownView`.
    @available(macOS 14.0, iOS 17.0, *)
    public struct Theme: Sendable, CaseIterable, Hashable, Identifiable {
        public var id: Self { self }
        
        public static var allCases: [MarkdownView.Theme] {
            [.concise, .blood, .boundless, .github, .succinct, .tree]
        }
        
        private let styleURL: URL
        /// The display name of the current theme.
        public let name: String
        /// The color configurations supported by the current theme.
        public let colorSupport: ColorSupport
        /// An enumeration representing the color configurations supported by the theme.
        public enum ColorSupport: Sendable {
            case dark
            case light
            case dynamic
        }
        
        private init(styleName: String, fileName: String, color: ColorSupport) {
            self.name = styleName
            guard let fileURL = Bundle.module.url(forResource: fileName, withExtension: "css") else {
                fatalError("[\(Self.self)][\(#function)] Resource file named `\(fileName).css` not found. Please check the package resources carefully.")
            }
            styleURL = fileURL
            colorSupport = color
        }
        
        public static let concise   = Self(styleName: "Concise", fileName: "concise", color: .dynamic)
        public static let github    = Self(styleName: "GitHub", fileName: "github", color: .dynamic)
        public static let blood     = Self(styleName: "Blood", fileName: "blood", color: .light)
        public static let boundless = Self(styleName: "Boundless Left", fileName: "boundless_left", color: .light)
        public static let tree      = Self(styleName: "Tree", fileName: "tree", color: .light)
        public static let succinct  = Self(styleName: "Succinct Cyan", fileName: "succinct_cyan", color: .light)
        
        var styleContent: String {
            guard let content = try? String(contentsOf: styleURL, encoding: .utf8) else {
                fatalError("[\(Self.self)][\(#function)] Style file `\(styleURL.path(percentEncoded: false))` cannot be read properly. Please check the package resources carefully.")
            }
            return content
        }
    }
}

#endif
