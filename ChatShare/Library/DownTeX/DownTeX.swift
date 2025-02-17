//
//  DownTeX.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

import SwiftUI
import UIKit
import WebKit

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
    
    private struct PlaceHolder: UIViewRepresentable {
        func makeUIView(context: Context) -> DownTeX.PandocView { DownTeX.pandocView }
        func updateUIView(_ uiView: DownTeX.PandocView, context: Context) {}
    }
    
    static var placeHolder: some View { PlaceHolder() }
    
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
            await self.configurePandocView()
            self.state = .ready
        }
    }
    
    /// Configure the web page loading for `PandocView`.
    private func configurePandocView(onCompletion: @escaping () async throws -> ()) {
        Task {
            await self.configurePandocView()
            try await onCompletion()
        }
    }
    
    /// Configure the web page loading for `PandocView`.
    private func configurePandocView() async {
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
            await configurePandocView()
            return
        }
        let checkPandocReady = {
            (try? await Self.pandocView.content.evaluateJavaScript("window.pandoc === undefined")) as? Bool
        }
        while true {
            let result = await checkPandocReady()
            guard let result else {
                await configurePandocView()
                return
            }
            if !result { break }
            try? await Task.sleep(for: .microseconds(100))
        }
    }
    
    public func convertToLaTeX(markdownString: String) async throws(OperationError) -> String {
        if self.state == .initFailed { throw .resourceFailured }
        while self.state != .ready {
            try? await Task.sleep(for: .microseconds(10))
        }
        self.state = .running
        let safedString = markdownString.javaScriptString
        let fetchResult = {
            (try? await Self.pandocView.content.evaluateJavaScript("window.pandoc('-f markdown -t latex', \"\(safedString)\")")) as? String
        }
        guard let result = await fetchResult() else {
            await configurePandocView()
            if let result = await fetchResult() {
                return result
            } else {
                throw .illegalTextContent
            }
        }
        return result
    }
}


extension DownTeX {
    class NavigationDelegate: NSObject, WKNavigationDelegate {
        weak var downTeX: DownTeX?
    }
}
