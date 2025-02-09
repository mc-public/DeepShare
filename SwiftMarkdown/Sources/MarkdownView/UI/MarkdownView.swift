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

@MainActor
@available(macOS 14.0, iOS 17.0, *)
public class MarkdownViewController: ObservableObject {
    public let container = MarkdownView.WebView()
    public var isRenderingContent: Bool = true
    public var onLinkActivation: ((URL) -> Void)? = nil
    
    
    public init() {}
}


@available(macOS 14.0, iOS 17.0, *)
public struct MarkdownView: PlatformViewRepresentable {
    
    @ObservedObject var controller: MarkdownViewController
    
    private(set) var markdownContent: String
    private(set) var linkActivationHandler: ((URL) -> Void)?
    private(set) var renderedContentHandler: ((String) -> Void)?
    private(set) var webviewHandler: ((WebView) -> Void)?
    
    public init(_ markdownContent: String, controller: MarkdownViewController) {
        self.markdownContent = markdownContent
        linkActivationHandler = nil
        renderedContentHandler = nil
        webviewHandler = nil
        self._controller = .init(wrappedValue: controller)
    }
    
    init(_ markdownContent: String, linkActivationHandler: ((URL) -> Void)?, renderedContentHandler: ((String) -> Void)?, webview: ((WebView) -> Void)?, controller: MarkdownViewController) {
        self.markdownContent = markdownContent
        self.linkActivationHandler = linkActivationHandler
        self.renderedContentHandler = renderedContentHandler
        self.webviewHandler = webview
        self._controller = .init(initialValue: controller)
    }
    
    public func makeCoordinator() -> Coordinator {
        .init(parent: self)
    }
    
#if os(macOS)
    public func makeNSView(context: Context) -> WebView {
        context.coordinator.platformView
    }
#elseif os(iOS)
    public func makeUIView(context: Context) -> WebView {
        context.coordinator.platformView!
    }
#endif
    
    func updatePlatformView(_ platformView: WebView, context _: Context) {
        guard !platformView.isLoading else { return } /// This function might be called when the page is still loading, at which time `window.proxy` is not available yet.
        platformView.updateMarkdownContent(markdownContent)
    }
    
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
        current.linkActivationHandler = linkActivationHandler
        return current
    }
    
    public func onRendered(_ renderedContentHandler: @escaping (String) -> Void) -> Self {
        var current = self
        current.renderedContentHandler = renderedContentHandler
        return current
    }
    
    public func withWebView(_ webviewHandler: @escaping (WebView) -> Void) -> Self {
        var current = self
        current.webviewHandler = webviewHandler
        return current
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: MarkdownView
        weak var platformView: WebView?
        var startTime: CFAbsoluteTime?
        
        init(parent: MarkdownView) {
            startTime = CFAbsoluteTimeGetCurrent()
            self.parent = parent
            platformView = .init()
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
            (webView as! WebView).updateMarkdownContent(parent.markdownContent)
        }
        
        public func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated {
                guard let url = navigationAction.request.url else { return .cancel }
                if let linkActivationHandler = parent.linkActivationHandler {
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
            if let webviewHandler = parent.webviewHandler {
                webviewHandler(platformView)
            }
            switch message.name {
                case "sizeChangeHandler":
                    guard let contentHeight = message.body as? CGFloat,
                          platformView.contentHeight != contentHeight
                    else { return }
                    platformView.contentHeight = contentHeight
                    platformView.bounds.size.height = contentHeight
                    platformView.invalidateIntrinsicContentSize()
                case "renderedContentHandler":
                    if let startTime = startTime {
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let renderTime = endTime - startTime
                        print("Markdown rendering time: \(renderTime) seconds")
                        self.startTime = nil
                    }
                    guard let renderedContentHandler = parent.renderedContentHandler,
                          let renderedContentBase64Encoded = message.body as? String,
                          let renderedContentBase64EncodedData: Data = .init(base64Encoded: renderedContentBase64Encoded),
                          let renderedContent = String(data: renderedContentBase64EncodedData, encoding: .utf8)
                    else { return }
                    renderedContentHandler(renderedContent)
                    Task {
                        if #available(iOS 16.0, macOS 13.0, *) {
                            await platformView.updateTheme(for: .github)
                            await platformView.updateTheme(for: .blood)
                            await platformView.updateFontSize(25)
                        }
                    }
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
