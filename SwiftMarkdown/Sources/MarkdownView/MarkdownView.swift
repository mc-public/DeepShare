import SwiftUI
import WebKit
import PDFKit

#if os(macOS)
    typealias PlatformViewRepresentable = NSViewRepresentable
#elseif os(iOS)
    typealias PlatformViewRepresentable = UIViewRepresentable
#endif

#if !os(visionOS)
    @available(macOS 11.0, iOS 14.0, *)
    public struct MarkdownView: PlatformViewRepresentable {
        var markdownContent: String
        let customStylesheet: String?
        let linkActivationHandler: ((URL) -> Void)?
        let renderedContentHandler: ((String) -> Void)?
        let webviewHandler: ((WebView) -> Void)?

        public init(_ markdownContent: String, customStylesheet: String? = nil) {
            self.markdownContent = markdownContent
            self.customStylesheet = customStylesheet
            linkActivationHandler = nil
            renderedContentHandler = nil
            webviewHandler = nil
        }

        init(_ markdownContent: String, customStylesheet: String?, linkActivationHandler: ((URL) -> Void)?, renderedContentHandler: ((String) -> Void)?, webview: ((WebView) -> Void)?) {
            self.markdownContent = markdownContent
            self.customStylesheet = customStylesheet
            self.linkActivationHandler = linkActivationHandler
            self.renderedContentHandler = renderedContentHandler
            self.webviewHandler = webview
        }

        public func makeCoordinator() -> Coordinator { .init(parent: self) }

        #if os(macOS)
            public func makeNSView(context: Context) -> CustomWebView { context.coordinator.platformView }
        #elseif os(iOS)
            public func makeUIView(context: Context) -> WebView { context.coordinator.platformView }
        #endif

        func updatePlatformView(_ platformView: WebView, context _: Context) {
            guard !platformView.isLoading else { return } /// This function might be called when the page is still loading, at which time `window.proxy` is not available yet.
            platformView.updateMarkdownContent(markdownContent)
        }

        #if os(macOS)
        public func updateNSView(_ nsView: CustomWebView, context: Context) {
            updatePlatformView(nsView, context: context)
        }
        #elseif os(iOS)
        public func updateUIView(_ uiView: WebView, context: Context) {
            updatePlatformView(uiView, context: context)
        }
        #endif

        public func onLinkActivation(_ linkActivationHandler: @escaping (URL) -> Void) -> Self {
            .init(markdownContent, customStylesheet: customStylesheet, linkActivationHandler: linkActivationHandler, renderedContentHandler: renderedContentHandler, webview: webviewHandler)
        }

        public func onRendered(_ renderedContentHandler: @escaping (String) -> Void) -> Self {
            .init(markdownContent, customStylesheet: customStylesheet, linkActivationHandler: linkActivationHandler, renderedContentHandler: renderedContentHandler, webview: webviewHandler)
        }
        
        public func withWebView(_ webviewHandler: @escaping (WebView) -> Void) -> Self {
            .init(markdownContent, customStylesheet: customStylesheet, linkActivationHandler: linkActivationHandler, renderedContentHandler: renderedContentHandler, webview: webviewHandler)
        }

        public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
            let parent: MarkdownView
            let platformView: WebView
            var startTime: CFAbsoluteTime?

            init(parent: MarkdownView) {
                startTime = CFAbsoluteTimeGetCurrent()
                self.parent = parent
                platformView = .init()
                super.init()

                platformView.navigationDelegate = self

                #if DEBUG && os(iOS)
                    if #available(iOS 16.4, *) {
                        self.platformView.isInspectable = true
                    }
                #endif

                /// So that the `View` adjusts its height automatically.
                platformView.setContentHuggingPriority(.required, for: .vertical)

                /// Disables scrolling.
                #if os(iOS)
                    platformView.scrollView.isScrollEnabled = false
                #endif

                /// Set transparent background.
                #if os(macOS)
                    platformView.setValue(false, forKey: "drawsBackground")
                /// Equavalent to `.setValue(true, forKey: "drawsTransparentBackground")` on macOS 10.12 and before, which this library doesn't target.
                #elseif os(iOS)
                    platformView.isOpaque = false
                #endif

                /// Receive messages from the web view.
                platformView.configuration.userContentController = .init()
                platformView.configuration.userContentController.add(self, name: "sizeChangeHandler")
                platformView.configuration.userContentController.add(self, name: "renderedContentHandler")
                platformView.configuration.userContentController.add(self, name: "copyToPasteboard")

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
                    print("Failed to load resources.")
                    return
                }

                // Append custom styles
                let stylesheet: String? = self.parent.customStylesheet.map { str in
                    defaultStylesheet + str
                }

                let htmlString = templateString
                    .replacingOccurrences(of: "PLACEHOLDER_SCRIPT", with: script)
                    .replacingOccurrences(of: "PLACEHOLDER_STYLESHEET", with: stylesheet ?? defaultStylesheet)
                if #available(iOS 16.0, *) {
                    print(Bundle.module.bundleURL.path(percentEncoded: false))
                } else {
                    // Fallback on earlier versions
                }
                platformView.loadHTMLString(htmlString, baseURL: Bundle.module.bundleURL.appendingPathComponent("index", conformingTo: .html))
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
                if let webviewHandler = parent.webviewHandler {
                    webviewHandler(platformView)
                }
                switch message.name {
                case "sizeChangeHandler":
                    guard let contentHeight = message.body as? CGFloat,
                          platformView.contentHeight != contentHeight
                    else { return }
                    platformView.contentHeight = contentHeight
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
                case "copyToPasteboard":
                    guard let base64EncodedString = message.body as? String else { return }
                    base64EncodedString.trimmingCharacters(in: .whitespacesAndNewlines).copyToPasteboard()
                default:
                    return
                }
            }
        }
        
        /// The internal `WKWebView` for displaying the markdown content.
        public class WebView: WKWebView {
            var contentHeight: CGFloat = 0
            /// The natural size for the receiving view, considering only properties of the view itself.
            override public var intrinsicContentSize: CGSize {
                .init(width: super.intrinsicContentSize.width, height: contentHeight)
            }
            
            /// The enumerate representing the element rect in the view.
            public enum ElementRect {
                case h1(rect: CGRect)
                case h2(rect: CGRect)
                case h3(rect: CGRect)
                case h4(rect: CGRect)
                case h5(rect: CGRect)
                case h6(rect: CGRect)
                case paragraph(rect: CGRect)
                case orderList(rect: CGRect, subNodeRects: [CGRect])
                case disorderList(rect: CGRect, subNodeRects: [CGRect])
                case quoteBlock(rect: CGRect)
                case section(rect: CGRect)
                case divBlock(rect: CGRect)
                case unknown(rect: CGRect)
            }
            
            /// Get all the element frame about the markdown document.
            func primaryElementsFrame() async -> [ElementRect] {
                let javascript = """
                function getAllSubnodeFrames(node) {
                    var childDivs = node.childNodes;
                    var frames = [];
                    for (var i = 0; i < childDivs.length; i++) {
                        try {
                            var rect = childDivs[i].getBoundingClientRect();
                            var nodeName = childDivs[i].nodeName
                            frames.push({
                                x: rect.x,
                                y: rect.y,
                                width: rect.width,
                                height: rect.height,
                                node: nodeName
                            });
                        } catch { }
                    }
                    return frames
                }

                var parentDiv = document.getElementById('markdown-rendered');
                var childDivs = parentDiv.childNodes;
                var frames = [];
                for (var i = 0; i < childDivs.length; i++) {
                    let currentNode = childDivs[i]
                    try {
                        var rect = currentNode.getBoundingClientRect();
                        var nodeName = currentNode.nodeName
                        let subframes = []
                        if ((nodeName === "UL") || (nodeName === "OL")) {
                            subframes = getAllSubnodeFrames(currentNode)
                        }
                        frames.push({
                            x: rect.x,
                            y: rect.y,
                            width: rect.width,
                            height: rect.height,
                            node: nodeName,
                            subnodes: subframes
                        });
                    } catch { }
                }
                frames;
                """
                var rectArray = [ElementRect]()
                let result = try? await self.evaluateJavaScript(javascript)
                func getCGRectFromResultItem(_ result: [String : Any]) -> CGRect? {
                    if let x = result["x"] as? CGFloat, let y = result["y"] as? CGFloat, let width = result["width"] as? CGFloat, let height = result["height"] as? CGFloat {
                        return CGRect(x: x, y: y, width: width, height: height)
                    }
                    return nil
                }
                if let frames = result as? [[String: Any]] {
                    for frame in frames {
                        if let cgRect = getCGRectFromResultItem(frame), let nodeName = frame["node"] as? String {
                            let subNodes = (frame["subnodes"] as? [[String: Any]] ?? []).compactMap { getCGRectFromResultItem($0) }
                            let elementRect: ElementRect = switch nodeName.uppercased() {
                                case "H1": .h1(rect: cgRect)
                                case "H2": .h2(rect: cgRect)
                                case "H3": .h3(rect: cgRect)
                                case "H4": .h4(rect: cgRect)
                                case "H5": .h5(rect: cgRect)
                                case "H6": .h6(rect: cgRect)
                                case "SECTION": .section(rect: cgRect)
                                case "P": .paragraph(rect: cgRect)
                                case "UL": .disorderList(rect: cgRect, subNodeRects: subNodes)
                                case "OL": .orderList(rect: cgRect, subNodeRects: subNodes)
                                case "BLOCKQUOTE": .quoteBlock(rect: cgRect)
                                case "DIV": .divBlock(rect: cgRect)
                                default: .unknown(rect: cgRect)
                            }
                            rectArray.append(elementRect)
                        }
                    }
                }
                return rectArray
            }
            
            @available(iOS 17.0, *)
            public func contentImage(width: CGFloat? = UIScreen.main.bounds.width) async -> UIImage? {
                let config = WKPDFConfiguration()
                config.allowTransparentBackground = true
                guard let pdfData = try? await self.pdf(configuration: config) else {
                    return nil
                }
                guard let pdfDocument = PDFDocument(data: pdfData) else {
                    return nil
                }
                assert(pdfDocument.pageCount == 1)
                guard let page = pdfDocument.page(at: 0) else {
                    return nil
                }
                let width = width ?? self.bounds.width
                return await Task.detached {
                    let pageSize = page.bounds(for: .mediaBox).size
                    let targetHeight = (width / pageSize.width) * pageSize.height
                    return page.thumbnail(of: CGSize(width: width, height: targetHeight), for: .mediaBox)
                }.value
            }
    
            
            @available(iOS 17.0, *)
            public func splitToImages(width: CGFloat? = nil) async -> [UIImage] {
                let elementRects = await self.primaryElementsFrame()
                if elementRects.isEmpty { return [] }
                /// Split the page according to the primary elements in the markdown file.
                var splitHeights: [CGFloat] = []
                func addBlackSubview(for rect: CGRect) {
                    let view = UIView()
                    view.layer.borderWidth = 2.0
                    self.addSubview(view)
                    view.frame = rect
                }
                for elementRect in elementRects {
                    switch elementRect {
                        case .h1(let rect):
                            addBlackSubview(for: rect)
                        case .h2(let rect):
                            addBlackSubview(for: rect)
                        case .h3(let rect):
                            addBlackSubview(for: rect)
                        case .h4(let rect):
                            addBlackSubview(for: rect)
                        case .h5(let rect):
                            addBlackSubview(for: rect)
                        case .h6(let rect):
                            addBlackSubview(for: rect)
                        case .paragraph(let rect):
                            addBlackSubview(for: rect)
                        case .orderList(let rect, let subNodeRects):
                            addBlackSubview(for: rect)
                            for subNodeRect in subNodeRects {
                                addBlackSubview(for: subNodeRect)
                            }
                        case .disorderList(let rect, let subNodeRects):
                            addBlackSubview(for: rect)
                            for subNodeRect in subNodeRects {
                                addBlackSubview(for: subNodeRect)
                            }
                        case .quoteBlock(let rect):
                            addBlackSubview(for: rect)
                        case .section(let rect):
                            addBlackSubview(for: rect)
                        case .divBlock(let rect):
                            addBlackSubview(for: rect)
                        case .unknown(let rect):
                            addBlackSubview(for: rect)
                    }
                }
                return []
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

            func updateMarkdownContent(_ markdownContent: String) {
                guard let markdownContentBase64Encoded = markdownContent.data(using: .utf8)?.base64EncodedString() else { return }

                callAsyncJavaScript("window.updateWithMarkdownContentBase64Encoded(`\(markdownContentBase64Encoded)`)", in: nil, in: .page, completionHandler: nil)
            }

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
