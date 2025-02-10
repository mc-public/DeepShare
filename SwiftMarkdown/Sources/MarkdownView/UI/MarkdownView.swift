//
//  MarkdownView+WebView.swift
//  SwiftMarkdown
//
//  Created by 孟超 on 2025/2/9.
//

import SwiftUI
import WebKit
import PDFKit

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformImage = NSImage
public typealias PlatformView = NSView
#elseif os(iOS)
typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformImage = UIImage
public typealias PlatformView = UIView
#endif

#if !os(visionOS)

/// The class used to perform control over `MarkdownView`.
@MainActor @Observable
@available(macOS 14.0, iOS 17.0, *)
public class MarkdownViewController {
    
    public typealias Theme = MarkdownView.Theme
    
    /// A subclass instance of WKWebView that displays Markdown text content.
    @ObservationIgnored
    public let container = MarkdownView.WebView()
    
    /// Indicates whether a Markdown rendering operation is currently in progress.
    ///
    /// The default value is `true`. This value can only become false after the first load is completed.
    public private(set) var isRenderingContent: Bool = true
    
    /// The text displayed in the current Markdown view.
    ///
    /// The default value is an empty string.
    public var text: String = "" {
        didSet {
            Task { await updateText(await: false) }
        }
    }
    
    /// The theme displayed in the current Markdown view.
    ///
    /// The default theme is `.github`.
    public var theme: Theme = .github {
        didSet {
            Task { await updateTheme(theme) }
        }
    }
    
    /// The font size about the Markdown content.
    ///
    /// The default value is `16.0`.
    /// - Warning: The font size must be within the range [3, 25].
    public var fontSize: CGFloat = 16.0 {
        didSet {
            Task { await updateFontSize(fontSize) }
        }
    }
    
    /// The background color about the Markdown content.
    ///
    /// The default color is `.white`.
    public var backgroundColor: Color {
        didSet {
            container.backgroundColor = UIColor(backgroundColor)
            container.scrollView.backgroundColor = UIColor(backgroundColor)
        }
    }
    
    @ObservationIgnored
    var onLinkActivation: ((URL) -> Void)? = nil
    @ObservationIgnored
    var onContentRendered: (() async throws -> Void)? = nil
    
    /// Set the text displayed in the current Markdown view.
    public func setText(_ content: String) async {
        await updateText(await: false)
    }
    
    /// Set the font size about the Markdown content.
    public func setFontSize(_ fontSize: CGFloat) async {
        await updateFontSize(fontSize)
    }
    
    /// Set the theme displayed in the current Markdown view.
    public func setTheme(_ theme: Theme) async {
        await updateTheme(theme)
    }
    
    func updateText(await: Bool = false) async {
        if container.isLoading { return }
        self.isRenderingContent = true
        await container.updateMarkdownContent(self.text)
        await updateTheme(theme)
        await updateFontSize(fontSize)
        if `await` {
            try? await Task.sleep(for: .seconds(0.2))
        }
        self.isRenderingContent = false
        try? await onContentRendered?()
    }
    
    func updateTheme(_ theme: MarkdownView.Theme) async {
        await container.updateTheme(for: theme)
        await container.updateFontSize(fontSize)
    }
    
    func updateFontSize(_ size: CGFloat) async {
        assert(size >= 3 && size <= 25, "[\(Self.self)][\(#function)] The font size must be within the range [3, 25]. This assertion will be ignored in release mode.")
        let size = max(3, min(25, size))
        await container.updateTheme(for: theme)
        await container.updateFontSize(size)
    }
    
    /// Create a `MarkdownView` controller.
    public init() {
        backgroundColor = .white
        container.backgroundColor = UIColor(.white)
    }
    
}


@available(macOS 14.0, iOS 17.0, *)
public struct MarkdownView: PlatformViewRepresentable {
    
    @Binding var controller: MarkdownViewController
    
    var markdownContent: String {
        controller.text
    }

    public init(controller: Binding<MarkdownViewController>) {
        self._controller = controller
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(controller: controller)
    }
    
#if os(macOS)
    public func makeNSView(context: Context) -> WebView {
        context.coordinator.platformView
    }
#elseif os(iOS)
    public func makeUIView(context: Context) -> WebView {
        controller.container
    }
#endif
    
    func updatePlatformView(_ platformView: WebView, context: Context) {}
    
#if os(macOS)
    public func updateNSView(_ nsView: WebView, context: Context) {
        updatePlatformView(nsView, context: context)
    }
#elseif os(iOS)
    public func updateUIView(_ uiView: WebView, context: Context) {
        updatePlatformView(uiView, context: context)
    }
#endif
    
    public func onLinkActivation(_ linkActivationHandler: @escaping (URL) -> Void) -> Self {
        var current = self
        current.controller.onLinkActivation = linkActivationHandler
        return current
    }
    
    public func onRendered(_ renderedContentHandler: @escaping () async throws -> Void) -> Self {
        var current = self
        current.controller.onContentRendered = renderedContentHandler
        return current
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var platformView: WebView?
        weak var controller: MarkdownViewController?
        var startTime: CFAbsoluteTime?
        
        init(controller: MarkdownViewController) {
            startTime = CFAbsoluteTimeGetCurrent()
            platformView = controller.container
            self.controller = controller
            super.init()
            
            platformView?.navigationDelegate = self
            
#if DEBUG && os(iOS)
            if #available(iOS 16.4, *) {
                self.platformView?.isInspectable = true
            }
#endif
            /// So that the `View` adjusts its height automatically.
            platformView?.setContentHuggingPriority(.required, for: .vertical)
            /// Disables scrolling.
#if os(iOS)
            platformView?.scrollView.isScrollEnabled = false
#endif
            /// Set transparent background.
#if os(macOS)
            platformView?.setValue(false, forKey: "drawsBackground")
            /// Equavalent to `.setValue(true, forKey: "drawsTransparentBackground")` on macOS 10.12 and before, which this library doesn't target.
#elseif os(iOS)
            platformView?.isOpaque = false
#endif
            /// Receive messages from the web view.
            platformView?.configuration.userContentController = .init()
            platformView?.configuration.userContentController.add(self, name: "sizeChangeHandler")
            platformView?.configuration.userContentController.add(self, name: "renderedContentHandler")
            platformView?.configuration.userContentController.add(self, name: "copyToPasteboard")
#if os(macOS)
            let defaultStylesheetFileName = "default-macOS"
#elseif os(iOS)
            let defaultStylesheetFileName = "default-iOS"
#endif
            guard let templateFileURL = Bundle.module.url(forResource: "template", withExtension: "html"),
                  let templateString = try? String(contentsOf: templateFileURL),
                  let scriptFileURL = Bundle.module.url(forResource: "script", withExtension: ""),
                  let script = try? String(contentsOf: scriptFileURL),
                  let defaultStylesheetFileURL = Bundle.module.url(forResource: defaultStylesheetFileName, withExtension: ""),
                  let defaultStylesheet = try? String(contentsOf: defaultStylesheetFileURL)
            else {
                fatalError("[\(MarkdownView.self)][FatalError] Failed to load resources. Please check resource files. ")
            }
            // Append custom styles
            let stylesheet: String? = defaultStylesheet
            
            let htmlString = templateString
                .replacingOccurrences(of: "PLACEHOLDER_SCRIPT", with: script)
                .replacingOccurrences(of: "PLACEHOLDER_STYLESHEET", with: stylesheet ?? defaultStylesheet)
            platformView?.loadHTMLString(htmlString, baseURL: Bundle.module.bundleURL.appendingPathComponent("index", conformingTo: .html))
        }
        
        /// Update the content on first finishing loading.
        public func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            guard let webView = webView as? WebView else { fatalError() }
            Task {
                await self.controller?.updateText(await: true)
            }
        }
        
        public func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated {
                guard let url = navigationAction.request.url else { return .cancel }
                if let linkActivationHandler = controller?.onLinkActivation {
                    linkActivationHandler(url)
                } else {
#if os(macOS)
                    NSWorkspace.shared.open(url)
#elseif os(iOS)
                    DispatchQueue.main.async {
                        Task { await UIApplication.shared.open(url) }
                    }
#endif
                }
                return .cancel
            } else {
                return .allow
            }
        }
        
        public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let platformView else { return }
            switch message.name {
                case "sizeChangeHandler":
                    guard let contentHeight = message.body as? CGFloat,
                          platformView.contentHeight != contentHeight
                    else { return }
                    platformView.contentHeight = contentHeight
                    platformView.bounds.size.height = contentHeight
                    platformView.invalidateIntrinsicContentSize()
                case "copyToPasteboard":
                    guard let base64EncodedString = message.body as? String else { return }
                    base64EncodedString.trimmingCharacters(in: .whitespacesAndNewlines).copyToPasteboard()
                default:
                    return
            }
        }
    }
}
#endif

extension String {
    func copyToPasteboard() {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self, forType: .string)
#else
        UIPasteboard.general.string = self
#endif
    }
}
