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

extension MarkdownView {
    /// The internal `WKWebView` for displaying the markdown content.
    public class WebView: WKWebView {
        /// The content height of current non-scrollable view.
        var contentHeight: CGFloat = 0
        /// The natural size for the receiving view, considering only properties of the view itself.
        override public var intrinsicContentSize: CGSize {
            .init(width: super.intrinsicContentSize.width, height: contentHeight)
        }
        
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

extension MarkdownView.WebView {
    /// Update markdown text in the webview.
    func updateMarkdownContent(_ markdownContent: String) {
        Task.detached {
            let patternLeft = "(?<!\\n\\n)\\\\\\["
            let patternRight = "\\\\\\](?!\\n\\n)"
            let formatedString = markdownContent
                .replacingOccurrences(of: patternLeft, with: "\n\n\\\\[", options: .regularExpression)
                .replacingOccurrences(of: patternRight, with: "\\\\]\n\n")
            guard let markdownContentBase64Encoded = formatedString.data(using: .utf8)?.base64EncodedString() else {
                return
            }
            DispatchQueue.main.async {
                self.evaluateJavaScript("window.updateWithMarkdownContentBase64Encoded(`\(markdownContentBase64Encoded)`)", completionHandler: nil)
            }
            
        }
    }
}

#endif
