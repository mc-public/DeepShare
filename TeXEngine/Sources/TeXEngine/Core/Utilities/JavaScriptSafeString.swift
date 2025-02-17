//
//  JavaScriptSafeString.swift
//  
//
//  Created by mengchao on 2023/7/20.
//

import Foundation

extension String {
    /// 返回可以传递给 ``JavaScript`` 的字符串
    ///
    /// 本字符串由 ``self`` 转换得到，可以安全传递给 ``JavaScriptCore`` 和 ``WKWebView`` 以执行 ``JavaScript`` 脚本。
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
    /// 把当前字符串修改为可以传递给 ``JavaScript`` 的字符串
    ///
    /// 修改后的字符串可以安全传递给 ``JavaScriptCore`` 和 ``WKWebView`` 以执行 ``JavaScript`` 脚本。
    mutating func setToJavaScript() {
        self = self.javaScriptString
    }
}
