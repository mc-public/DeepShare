//
//  TeXEngine+navigation.swift
//
//
//  Created by 孟超 on 2024/2/5.
//

import Foundation
import WebKit

class TeXNavigationDelegate: NSObject, WKNavigationDelegate {
    
    weak var engine: TeXEngine?
    
    init(engine: TeXEngine) {
        self.engine = engine
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let engine = self.engine else {
            return
        }
        Task { @MainActor in
            guard let _ = engine.fileQuerier, let _ = engine.webView else {
                fatalError("[TeXEngine][Internal]这种情况不应发生，请立即联系框架开发者邮箱: 3100489505@qq.com")
            }
            engine.setWebViewCheckedContinuation?.resume(returning: true)
            engine.setWebViewCheckedContinuation = nil
        }
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let engine = self.engine else {
            return
        }
        Task { @MainActor in
            guard let _ = engine.fileQuerier, let _ = engine.webView else {
                fatalError("[TeXEngine][Internal]这种情况不应发生，请立即联系框架开发者邮箱: 3100489505@qq.com")
            }
            engine.setWebViewCheckedContinuation?.resume(returning: false)
        }
    }
    
    
    /// 当 WebView 被系统杀死时设置引擎的状态为 `crashed` 并发送通知
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
        guard let engine = self.engine else {
            return
        }
        Task { @MainActor in
            await engine.awaitNotWorking()
            if engine.state != .crashed { /* set crash state */
                NotificationCenter.default.post(name: TeXEngine.engineDidCrash, object: engine)
                engine.setState(.crashed)
            }
        }
        
    }
}
