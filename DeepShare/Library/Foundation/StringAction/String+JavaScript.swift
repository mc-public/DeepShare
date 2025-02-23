//
//  String+JavaScript.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

import Foundation

extension String {
    /// Returns a string that can be passed to ``JavaScript``.
    ///
    /// This string is converted from ``self`` and can be safely passed to ``JavaScriptCore`` and ``WKWebView`` to execute ``JavaScript`` scripts.
    var javaScriptString: String {
        var safeString  = self as NSString
        safeString = safeString.replacingOccurrences(of: "\\", with: "\\\\") as NSString
        safeString = safeString.replacingOccurrences(of: "\"", with: "\\\"") as NSString
        safeString = safeString.replacingOccurrences(of: "\'", with: "\\\'") as NSString
        safeString = safeString.replacingOccurrences(of: "\n", with: "\\n") as NSString
        safeString = safeString.replacingOccurrences(of: "\r", with: "\\r") as NSString
        safeString = safeString.replacingOccurrences(of: "\t", with: "\\t") as NSString
        safeString = safeString.replacingOccurrences(of: "\u{0085}", with: "\\u{0085}") as NSString
        safeString = safeString.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}") as NSString
        safeString = safeString.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}") as NSString
        return safeString as String
    }
    /// Modifies the current string to be safe for passing to ``JavaScript``.
    ///
    /// The modified string can be safely passed to ``JavaScriptCore`` and ``WKWebView`` to execute ``JavaScript`` scripts.
    mutating func setToJavaScript() {
        self = self.javaScriptString
    }
}
