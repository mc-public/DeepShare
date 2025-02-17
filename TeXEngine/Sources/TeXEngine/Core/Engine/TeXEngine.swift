//
//  TeXEngine.swift
//  
//
//  Created by 孟超 on 2023/7/21.
//

import Foundation
import WebKit


/// 用于操作 `XeTeX` 引擎进行编译的类
///
/// 在 iOS 或者 iPadOS 平台上运行 `XeTeX` 引擎的原理是，将 `XeTeX` 引擎的 `C` 源码使用  WebAssembly 技术编译为 wasm 二进制文件，并使用 `WebKit` 框架读取该二进制文件。
@MainActor
public class TeXEngine: TeXEngineProvider, ObservableObject {
    
    /// 当前引擎的具体信息
    public nonisolated(unsafe) let engineInfo: EngineInfoProvider
    
    /// 当前引擎的类型
    public var engineType: EngineType {
        engineInfo.type
    }
    
    /// 当前引擎是否支持 `Unicode` 编码
    ///
    /// 对于 `XeTeX` 引擎来说，该值永远是 `true`，这是因为 `XeTeX` 引擎是支持 Unicode 的现代 `TeX` 引擎。
    public var supportedUnicode: Bool {
        self.engineInfo.supportedUnicode
    }
    
    
    /// 当前引擎的代理
    ///
    /// 使用本类时如果想要观察本类的某些状态更改，可以实现代理的相关方法。
    public weak var delegate: (any TeXEngineDelegate)?
    
    /// 来自引擎的终端输出
    @Published public internal(set) var consoleOutput = String()
    /// 当前引擎的文件查询器
    public private(set) var fileQuerier: FileQueryProvider?
    /// 当前引擎的工作状态
    ///
    /// 本类的使用者需要根据引擎的不同状态调用相应的方法。
    @Published public private(set) var state: EngineState
    /// 当前引擎使用的 `xetex.fmt` 文件 `URL`
    ///
    /// 默认从框架中加载此文件，也可以自行指定该文件的 `URL`。
    private var plainFormatURL: URL? {
        get {
            self.engineInfo.plainFormatURL
        }
        set {
            self.engineInfo.latexFormatURL = newValue
        }
    }
    /// 当前引擎使用的 `xelatex.fmt` 文件的 `URL`
    ///
    /// 默认从框架中加载此文件，也可以自行指定该文件的 `URL`。
    private var latexFormatURL: URL? {
        get {
            self.engineInfo.latexFormatURL
        }
        set {
            self.engineInfo.latexFormatURL = newValue
        }
    }
    
    /// 为当前引擎的编译格式指定的格式文件的 `URL` 字典
    ///
    /// 设置本属性的值将导致执行编译时采用这里指定的格式文件。
    ///
    /// - Warning: 请勿删除该属性的键，否则在设置后将立即导致运行时错误。
    ///
    /// 默认采用本框架自带的格式文件。
    public var dynamicFormatURL: [CompileFormat : URL?]  {
        self.engineInfo.dynamicFormatURL
    }
    
    /// 当前供其它视图展示的视图
    ///
    /// 使用本类时需要把此视图展示在 UI 中以加速引擎的运行速度。
    public var view: UIView {
        webViewHolder
    }
    
    /// 当前供其它视图展示的视图
    var webViewHolder: UIViewHolder
    
    /// 当前的网络视图
    var webView: WKWebView? {
        didSet {
            webViewHolder.webview = webView
        }
    }
    /// 当前网络视图的导航代理
    ///
    /// 为了确保线程安全，该值在初始化以后不能再重新设置。
    @MainActor
    lazy var navigationDelegate = TeXNavigationDelegate(engine: self)
    
    /// 当前视图用于从 XeTeX 引擎处获取终端输出信息的代理
    lazy var outputDelegate =  Self.LogHandler.init(engine: self)
    
    deinit {
        self.fileQuerier = nil
        let view = self.webView
        Task { @MainActor in
            view?.removeFromSuperview()
        }
    }
    
    /// 初始化引擎
    ///
    /// 初始化引擎，可以在 `SwiftUI` 中作为视图的可观测对象。
    ///
    /// 调用本方法后，还需要初始化文件查询服务后才可以调用编译有关的方法。这需要在异步环境中调用 ``setFileQurier(texlive:)`` 。关于调用异步方法，可以查询 `Swift` 异步编程指南。例如，
    /// ```swift
    /// let engine = TeXEngine()
    /// Task {
    ///     try await engine.setFileQuerier(texlive: texmfURL)
    /// }
    ///
    /// ```
    public init(engineType: EngineType) {
        self.engineInfo = engineType.createEngineInfo()
        self.webViewHolder = .init()
        self.state = .inited
    }
    
    /// 加载当前引擎的文件查询服务与引擎内核
    ///
    /// 使用给定的 `texlive` 的 `TEXMF` 树的根目录去初始化当前的文件查询服务，并在加载完成后初始化当前的引擎内核。该过程可能需要一段时间。
    ///
    /// 如果文件查询服务已经被初始化一次了，调用本方法时将清理所有辅助文件并重新初始化文件查询服务，这将减慢下次编译所用的时间。
    ///
    /// - Note: 无需检测 `self.state.working` 的值是否为 `false`，该方法是线程安全的，可以随时在协程环境中调用此方法。
    ///
    /// - Parameter texmfRootDirectory: `texlive` 发行版的 `TEXMF` 根目录对应的文件夹的 `URL`。该目录中必须包含 `texmf-dist` 等文件夹，否则会抛出错误。
    /// - Throws: 本方法可能抛出错误。如果引擎内核加载错误，该方法将把引擎的状态更改为 `EngineState.crashed`，此时可以尝试调用 `self.cleanEngine()` 方法以重新加载引擎内核。如果文件查询器加载错误，该方法将把引擎的状态更改为 `EngineState.inited`。
    public func loadEngine(texlive texmfRootDirectory: URL) async throws {
        await self.awaitNotWorking()
        self.setState(.loadingFileQuerier)
        /* 在设置文件查询器时, 我们总是重新初始化 */
        self.fileQuerier = nil /* 置空以防止内存泄漏 */
        let fileQuerier: TeXFileQuerier
        do {
            fileQuerier = try await TeXFileQuerier(texlive: texmfRootDirectory, engine: self)
        } catch {
            self.setState(.inited)
            throw error
        }
        fileQuerier.texEngine = self
        self.fileQuerier = fileQuerier
        self.setState(.loadingEngineCore)
        do {
            try self.setWebView(fileQuerier: fileQuerier)
        } catch {
            self.setState(.crashed)
            throw error
        }
        let loadState = await withCheckedContinuation { checkedContinuation in
            self.setWebViewCheckedContinuation = checkedContinuation
        }
        if !loadState {
            self.setState(.crashed)
            throw EngineError.engineCoreLoadingFailured
        } else {
            self.setState(.ready)
            self.delegate?.engineDidLoadFileQuerier(engine: self, querier: fileQuerier)
        }
    }
    
    /// `setWebView` 的检查延续
    var setWebViewCheckedContinuation: CheckedContinuation<Bool, Never>?
    
    /// 设置运行 `TeX` 引擎的网络视图
    ///
    /// 原子方法内部不能设置当前引擎的状态。
    ///
    /// - Parameter querier: 注入到该网络视图的文件查询器。
    /// - Parameter scheme: 注入到该网络视图的 `URL` 域名。
    /// - Returns: 返回设置的结果，`true` 表示设置时成功，`false` 表示设置时出现错误。
    private func setWebView<T: FileQueryProvider>(fileQuerier: T, scheme: String = "texengine") throws  {
        let userContentController = WKUserContentController()
        userContentController.add(self.outputDelegate, name: self.outputDelegate.contentID)
        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        assert(fileQuerier is WKURLSchemeHandler, "[TeXEngine][Internal]文件查询器不遵循 WKURLSchemeHandler 协议! 请联系框架开发者: 3100489505@qq.com")
        config.setURLSchemeHandler(fileQuerier as? WKURLSchemeHandler, forURLScheme: scheme)
        let webview = WKWebView(frame: .zero, configuration: config)
        self.webView = webview
        webview.navigationDelegate = self.navigationDelegate /* Handle Crash */
        guard let engineHTML = Bundle.module.url(forResource: engineInfo.htmlFileName, withExtension: "html") else {
            #if DEBUG
            fatalError("[TeXEngine][Internal]无法找到引擎文件 XeTeXEngine.html，请联系框架开发者: 3100489505@qq.com")
            #else
            throw EngineError.engineFileNotFound
            #endif
        }
        if #available(iOS 16.4, *) {
            #if DEBUG
            webview.isInspectable = true
            #else
            webview.isInspectable = false
            #endif
        }
        webview.loadFileURL(engineHTML, allowingReadAccessTo: Bundle.module.resourceURL ?? engineHTML)
        
    }
    
    
    /// 重新加载当前引擎的内核
    ///
    /// 如果当前引擎的状态为 `EngineState.crashed`，您可以考虑调用此方法以将此状态恢复到 `EngineState.ready`。
    ///
    /// 此方法常用于解决引擎的内部崩溃。这些崩溃可能是由于 iOS 设备的内存不足导致的。
    ///
    /// - Note: 重置引擎的代价是下一次编译的用时很可能变长。
    ///
    /// - Warning: 在调用此方法前必须确认引擎已经加载了文件查询服务，即 `self.state.isLoadedFileQuerier` 的值必须为 `true`，否则将抛出相应的错误。
    /// - Warning: 此方法如果当前引擎的状态为 `EngineState.crashed`。
    public func reloadEngineCore() async throws {
        await self.awaitNotWorking()
        guard let fileQuerier = self.fileQuerier else {
            self.setState(.inited)
            throw EngineError.fileQurierNotLoaded
        }
        self.setState(.loadingEngineCore)
        self.webView = nil
        do {
            try self.setWebView(fileQuerier: fileQuerier)
        } catch {
            self.setState(.crashed)
            throw error
        }
        let loadState = await withCheckedContinuation { checkedContinuation in
            self.setWebViewCheckedContinuation = checkedContinuation
        }
        if !loadState {
            self.setState(.crashed)
            throw EngineError.engineCoreLoadingFailured
        } else {
            self.setState(.ready)
        }
    }
    
    /// 设置当前引擎的状态
    func setState(_ state: EngineState) {
        let oldState = self.state
        let newState = state
        self.state = newState
        if oldState != newState {
            self.delegate?.engineDidChangeState(engine: self, from: oldState, to: newState)
        }
    }
    
    /// 等待引擎为非工作状态
    func awaitNotWorking() async {
        while self.state.isWorking {
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
        }
    }
    
}


@MainActor
class UIViewHolder: UIView {
    
    weak var webview: WKWebView? {
        didSet {
            self.setSubView(for: webview)
        }
    }
    
    func setSubView(for subview: UIView?) {
        _ = self.subviews.map { $0.removeFromSuperview() }
        guard let subview = subview else {
            return
        }
        subview.translatesAutoresizingMaskIntoConstraints = false
        super.addSubview(subview)
        subview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}


extension TeXEngine {
    
    class LogHandler: NSObject, WKScriptMessageHandler {
        weak var engine: TeXEngine?
        var contentID = "TeXLogHandler"
        init(engine: TeXEngine) {
            self.engine = engine
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == self.contentID else {
                return
            }
            guard let content = message.body as? String else {
                return
            }
            Task { @MainActor in
                guard let engine = self.engine else {
                    return
                }
                engine.consoleOutput.append(content)
                engine.delegate?.outputToConsole(engine: engine, content: content)
            }
        }
    }
    
}
