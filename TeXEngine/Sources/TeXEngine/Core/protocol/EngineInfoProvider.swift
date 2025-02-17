//
//  EngineInfoProvider.swift
//
//
//  Created by 孟超 on 2024/2/17.
//

import Foundation
import SwiftUI

/// 表示当前框架中可用的引擎类型的名称的结构体
public struct EngineType: Equatable, Sendable {
    let rawValue: String
    public static let xetex = Self(rawValue: "xetex")
    public static let pdftex = Self(rawValue: "pdftex")
    
    func createEngineInfo() -> EngineInfoProvider {
        switch self {
        case .xetex:
            return XeTeXEngineInfo()
        case .pdftex:
            return PDFTeXEngineInfo()
        default:
            fatalError("[TeXEngine][Internal]此情形不应出现，请联系框架开发者邮箱：3100489505@qq.com 或者在 Github 上报告此问题。")
        }
    }
}

/// 为 `TeXEngine` 类提供特定于引擎的信息的类所应遵循的协议
public protocol EngineInfoProvider: AnyObject {
    
    /// 当前引擎的类型
    var type: EngineType { get }
    /// 当前引擎是否支持 Unicode 编码
    var supportedUnicode: Bool { get }
    /// 当前引擎使用的 `plain-tex` 格式文件的默认值
    var plainFormatURL: URL? { get set }
    /// 当前引擎使用的 `latex` 格式文件的默认值
    var latexFormatURL: URL? { get set }
    /// 当前引擎加载的网页文件的名称
    ///
    /// 实现此属性时应当移除 `html` 文件的扩展名。例如，如果文件是 `XeTeXEngine.html`，则该属性的值应为 `XeTeXEngine`。
    var htmlFileName: String { get }
    
    /// 判断某个来自 `texlive` 的资源文件是否可被当做编译源文件
    ///
    /// - Parameter texResourceURL: 想要被判断的编译源文件的 `URL`。
    /// - Returns: 实现本协议的类应当返回一个 `Bool` 值，该值表明了参数对应的文件是否可以被当做编译源文件。
    nonisolated func checkTeXResource(for texResourceURL: URL) -> Bool
    /// 当前引擎支持的格式对应的名称
    ///
    /// 符合本协议的类必须实现本方法以告诉调用者，当前期望使用的引擎格式对应的格式文件的名称。
    ///
    /// > 在实现时必须注意，返回的文件名所对应的文件，必须能被 **实现者的文件查询器** 查询到。一般来说，只需保证该文件名在 `texlive` 的 `TEXMF` 树中即可。
    /// - Returns: 应当返回 `ini` 文件的具体名称。例如，如果格式文件由 `xelatex.ini` 生成（对应的格式文件一定为 `xelatex.fmt`），则此方法应当返回 `xelatex.ini`。
    func getIniFileName(for format: CompileFormat) -> String
}

extension EngineInfoProvider {
    /// 为当前引擎的编译格式指定的格式文件的 `URL` 字典
    ///
    /// 设置本属性的值将导致执行编译时采用这里指定的格式文件。
    ///
    /// - Warning: 请勿删除该属性的键，否则在设置后将立即导致运行时错误。
    ///
    /// 默认采用本框架自带的格式文件。
    public var dynamicFormatURL: [CompileFormat : URL?] {
        var map = [CompileFormat : URL]()
        map[.latex] = self.latexFormatURL
        map[.biblatex] = self.latexFormatURL
        map[.plain] = self.plainFormatURL
        return map
    }
}


