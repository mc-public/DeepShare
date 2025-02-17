//
//  CompileFormat.swift
//
//
//  Created by 孟超 on 2024/2/10.
//

import Foundation

/// 所有可能的 `TeX` 引擎的编译格式的类型
///
/// 包含了 `plain-tex` 格式、`latex` 格式以及 `bibtex + latex` 格式。
///
/// 目前所有的 `TeX` 引擎均支持这两种格式。
public struct CompileFormat: Hashable, Sendable {
    
    /// `plain-tex` 格式
    public static let plain = Self.init(rawValue: "plain")
    /// `latex` 格式
    public static let latex = Self.init(rawValue: "latex")
    /// `bibtex` 与 `latex` 混合模式
    public static let biblatex = Self.init(rawValue: "biblatex")
    
    static var allCases: [CompileFormat] {
        [.plain, .latex, .biblatex]
    }

    let rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}
