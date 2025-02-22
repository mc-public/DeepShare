//
//  DownTeX.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

import SwiftUI
import UIKit
import WebKit
import TeXEngine
import Localization

/// A class for executing Markdown to LaTeX and PDF conversion.
@Observable @MainActor
public final class DownTeX {
    
    /// The singleton of the current class.
    public static let current = DownTeX()
    
    //MARK: Resources Properties
    @AppStorage("\(DownTeX.self)_Resources") @ObservationIgnored
    public var isResourcesLoaded = false
    
    //MARK: Pandoc View Configuration
    public typealias PandocView = UIDynamicView<WKWebView>
    
    private struct PandocPlaceHolder: UIViewRepresentable {
        func makeUIView(context: Context) -> DownTeX.PandocView { DownTeX.pandocView }
        func updateUIView(_ uiView: DownTeX.PandocView, context: Context) {}
    }
    
    private struct TeXPlaceHolder: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView { DownTeX.LaTeXEngine.view }
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    /// The place holder view for current controller.
    static var placeHolder: some View {
        VStack { PandocPlaceHolder(); TeXPlaceHolder() }
    }
    
    /// An enumeration representing the state of the current class.
    public enum State {
        /// Initializing resources.
        case initializing
        /// Initialization of resources failed.
        ///
        /// At this point, all methods will throw the corresponding errors.
        case initFailed
        /// The framework is ready to perform various operations.
        case ready
        /// The framework is performing an operation.
        case running
    }
    /// An enumeration representing the errors that a method of the framework might throw.
    public enum OperationError: Error {
        /// The resource file has not been loaded.
        case resourceFailured
        /// Illegal text content.
        case illegalTextContent
        /// File operation failed.
        case fileOperationFailured
    }
    /// The current state of the class.
    public var state: State = .initializing
    
    //MARK: - Private Properties
    
    private static var PandocViewConfiguration: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        return config
    }
    
    @ObservationIgnored
    private var navigationDelegate = NavigationDelegate()
    
    private static let pandocView = PandocView {
        WKWebView(frame: .zero, configuration: DownTeX.PandocViewConfiguration)
    }
    
    private static let LaTeXEngine = TeXEngine(engineType: .xetex)
    
    //MARK: - Init And Configuration
    
    private init() {
        self.state = .initializing
        self.navigationDelegate.downTeX = self
        if !Resources.isResourcesReady {
            let result = Resources.prepareResources()
            if !result {
                self.state = .initFailed
            }
        }
        Task {
            await self.unsafe_configurePandocView()
            await self.unsafe_configureTeXEngine()
            self.state = .ready
        }
    }
    
    private func unsafe_configureTeXEngine(onCompletion: @escaping () async throws -> ()) {
        Task {
            await self.unsafe_configureTeXEngine()
            try await onCompletion()
        }
    }
    
    private func unsafe_configureTeXEngine() async {
        do {
            try await Self.LaTeXEngine.loadEngine(texlive: Resources.TeXResources)
        } catch {
            if Self.LaTeXEngine.state == .crashed {
                await unsafe_configureTeXEngine()
                return
            } else {
                fatalError("[\(Self.self)][\(#function)] Fatal unknown error occurred about the `TeX-Resource-Files`.")
            }
        }
    }
    
    /// Configure the web page loading for `PandocView`.
    private func unsafe_configurePandocView(onCompletion: @escaping () async throws -> ()) {
        Task {
            await self.unsafe_configurePandocView()
            try await onCompletion()
        }
    }
    
    /// Configure the web page loading for `PandocView`.
    private func unsafe_configurePandocView() async {
        Self.pandocView.content = .init(frame: .zero, configuration: Self.PandocViewConfiguration)
#if DEBUG
        Self.pandocView.content.isInspectable = true
#endif
        Self.pandocView.content.navigationDelegate = self.navigationDelegate
        Self.pandocView.content.loadFileURL(Resources.PandocHTMLResource, allowingReadAccessTo: Resources.PandocResource)
        /// Checking load state.
        let startTime = Date.now
        var isFailured: Bool = false
        while Self.pandocView.content.isLoading {
            try? await Task.sleep(for: .microseconds(100))
            if abs(Date.now.distance(to: startTime)) > 4 {
                isFailured = true
            }
        }
        guard !isFailured else {
            await unsafe_configurePandocView()
            return
        }
        let checkPandocReady = {
            (try? await Self.pandocView.content.evaluateJavaScript("window.pandoc === undefined")) as? Bool
        }
        while true {
            let result = await checkPandocReady()
            guard let result else {
                await unsafe_configurePandocView()
                return
            }
            if !result { break }
            try? await Task.sleep(for: .microseconds(100))
        }
    }
    
    //MARK: - Public API
    /// Convert specific Markdown string to Microsoft-DOCX data.
    ///
    /// - Parameter markdownString: The markdown string.
    public func convertToDocx(markdownString: String) async throws(OperationError) -> Data {
        if self.state == .initFailed { throw .resourceFailured }
        while self.state != .ready {
            try? await Task.sleep(for: .microseconds(10))
        }
        self.state = .running
        defer { self.state = .ready }
        return try await unsafe_convertToDocx(markdownString: markdownString)
    }
    
    
    /// Convert specific Markdown string to specific plain-text string.
    ///
    /// - Parameter markdownString: The markdown string.
    /// - Parameter format: The target text-format.
    public func convertToText(markdownString: String, format: TargetFormat) async throws(OperationError) -> String {
        if self.state == .initFailed { throw .resourceFailured }
        while self.state != .ready {
            try? await Task.sleep(for: .microseconds(10))
        }
        self.state = .running
        defer { self.state = .ready }
        return try await unsafe_convertToText(markdownString: markdownString, format: format)
    }
    
    
    
    public struct TargetFormat: CaseIterable, Hashable, Identifiable, RawRepresentable, Sendable {
        
        fileprivate var command: String
        public var title: String
        public var rawValue: String { self.command }
        public var id: String { self.command }
        public var extensionName: String
        public static var allCases: [TargetFormat] {
            [.plainText, .reStructuredText, .latex, .html]
        }
        
        public init?(rawValue: String) {
            for item in Self.allCases + [.unsafe_latex] where item.command == rawValue {
                self.command = item.command
                self.title = item.title
                self.extensionName = item.extensionName
            }
            return nil
        }
        
        private init(command: String, title: String, extensionName: String) {
            self.command = command
            self.title = title
            self.extensionName = extensionName
        }
        
        public static let plainText = TargetFormat(command: "-f markdown -t plain", title: #localized("Plain Text"), extensionName: "txt")
        public static let reStructuredText = TargetFormat(command: "-f markdown -t rst", title: #localized("reStructuredText"), extensionName: "rst")
        public static let latex = TargetFormat(command: "--standalone -f markdown -t latex", title: #localized("LaTeX"), extensionName: "tex")
        public static let html = TargetFormat(command: "-f markdown -t html", title:  #localized("HTML"), extensionName: "html")
        fileprivate static let unsafe_latex = TargetFormat(command: "-f markdown -t latex", title: #localized("LaTeX"), extensionName: "tex")
    }
    
    //MARK: - Private API
    private func unsafe_convertToText(markdownString: String, format: TargetFormat) async throws(OperationError) -> String {
        if markdownString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String()
        }
        let safedString = markdownString.javaScriptString
        let fetchResult = {
            (try? await Self.pandocView.content.evaluateJavaScript("window.pandoc('\(format.command)', \"\(safedString)\")")) as? String
        }
        guard let result = await fetchResult() else {
            await unsafe_configurePandocView()
            return try await unsafe_convertToText(markdownString: markdownString, format: format)
        }
        return result
    }
    
    private func unsafe_convertToDocx(markdownString: String) async throws(OperationError) -> Data {
        if markdownString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Data()
        }
        let safedString = markdownString.javaScriptString
        let fetchResult = { () -> Data? in
            guard let base64String = (try? await Self.pandocView.content.evaluateJavaScript("window.pandoc_docx(\"\(safedString)\")")) as? String, !base64String.isEmpty else {
                return nil
            }
            return Data(base64Encoded: base64String)
        }
        guard let result = await fetchResult() else {
            await unsafe_configurePandocView()
            return try await unsafe_convertToDocx(markdownString: markdownString)
        }
        return result
    }
    
    //MARK: - Internal API
    
    func unsafe_convertToLaTeX(markdownString: String) async throws(OperationError) -> String {
        if markdownString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw .illegalTextContent
        }
        return try await unsafe_convertToText(markdownString: markdownString, format: .unsafe_latex)
    }
    
    func unsafe_compileToPDF(latexString: String, images: [String: UIImage]) async throws(OperationError) -> Data {
        let latexString = latexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if latexString.isEmpty {
            throw .illegalTextContent
        }
        let texDirURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: texDirURL, withIntermediateDirectories: true)
        } catch { throw .fileOperationFailured }
        
        let texURL = texDirURL.appending(path: "content.tex")
        if !FileManager.default.createFile(atPath: texURL.path(percentEncoded: false), contents: latexString.data(using: .utf8)) {
            throw .fileOperationFailured
        }
        for (fileName, image) in images {
            let imageURL = texDirURL.appending(path: fileName)
            if !FileManager.default.createFile(atPath: imageURL.path(percentEncoded: false), contents: image.pngData()) {
                throw .fileOperationFailured
            }
        }
        let result: CompileResult?
        do {
            result = try await Self.LaTeXEngine.compileTeX(by: .latex, tex: texURL)
        } catch {
            debugPrint(error)
            try? await Self.LaTeXEngine.reloadEngineCore()
            return try await self.unsafe_compileToPDF(latexString: latexString, images: images)
        }
        if let data = result?.pdf {
            return data
        } else {
            throw OperationError.illegalTextContent
        }
    }
}


extension DownTeX {
    private class NavigationDelegate: NSObject, WKNavigationDelegate {
        weak var downTeX: DownTeX?
    }
}
