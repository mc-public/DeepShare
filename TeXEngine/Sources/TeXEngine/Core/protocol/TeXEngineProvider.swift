//
//  TeXEngine.swift
//
//  Created by mengchao on 2023/7/20.
//

import Foundation
import WebKit



/// 引擎可能抛出的错误类型
public enum EngineError: Error  {
    /// 引擎的核心文件丢失
    case engineFileNotFound
    /// 文件查询器尚未加载，不能调用此方法
    case fileQurierNotLoaded
    /// 引擎的核心文件加载失败
    case engineCoreLoadingFailured
}

/// 编译格式时可能抛出的所有错误
public enum CompileFormatError: Error {
    /// 引擎在编译过程中发生了崩溃
    case engineCrashed
    /// 传入的 `ini` 文件在指定的 `texlive` 的 `TEXMF` 根目录中没有找到。
    case iniFileNotFound
    /// 引擎处于不可编译的其它状态
    ///
    /// 此时无法正常执行编译。
    case engineNotReady
    /// 编译 FMT 文件时引擎提示了失败。
    case compileFailured
    /// 编译 FMT 文件时在给定目录写入 FMT 文件时失败。
    case writeFormatFileFailured
}

/// 编译 `TeX` 文件时可能抛出的所有错误
public enum CompileTeXError: Error {
    /// 引擎在编译过程中发生了崩溃
    ///
    /// 这种情况下需要重启引擎
    case engineCrashed
    /// 引擎在编译过程中未找到指定的格式文件
    case formatFileNotFound
    /// 引擎处于不可执行编译的其它状态
    ///
    /// 此时无法正常执行编译。
    case engineNotReady
    /// 传入了格式不正确的 TeX 文件 `URL`
    ///
    /// 传入编译有关方法的 TeX 文件 `URL` 的文件名必须以 `tex` 结尾。
    case texFileFormatNotNormal
    /// 传入了不存在的 TeX 文件 `URL`
    case texFileNotFound
}






/// 某个具体的 TeX 引擎所应当遵循的协议
@MainActor
public protocol TeXEngineProvider: AnyObject {
    
    /// 特定于某些引擎的方法实现
    var engineInfo: EngineInfoProvider { get }
    
    /// 当前引擎的类型
    var engineType: EngineType { get }
    
    /// 当前引擎是否支持 `Unicode` 编码处理
    ///
    /// 该属性必须实现为不可变的计算属性。
    var supportedUnicode: Bool { get }
    
    /// 当前引擎的代理
    var delegate: (any TeXEngineDelegate)? { get set }
    
    /// 与引擎的相应实现对应的文件控制器
    var fileQuerier: FileQueryProvider? { get }
    
    /// 当前编译以后的控制台输出
    var consoleOutput: String { get }
    
    /// 为当前引擎的编译格式指定的动态编译文件夹
    ///
    /// 实现本属性的类应采取措施使得执行编译时采用这里指定的格式文件。
    ///
    /// - Warning: 实现本属性时请观察该属性的键的个数是否等于 `CompileFormat` 中枚举的个数，如果不相等应立即抛出运行时错误。
    var dynamicFormatURL: [CompileFormat : URL?] { get }
    
    /// 当前引擎支持的格式对应的名称
    ///
    /// 符合本协议的类必须实现本方法以告诉调用者，当前期望使用的引擎格式对应的格式文件的名称。
    ///
    /// > 在实现时必须注意，返回的文件名所对应的文件，必须能被 **实现者的文件查询器** 查询到。一般来说，只需保证该文件名在 `texlive` 的 `TEXMF` 树中即可。
    /// - Returns: 应当返回 `ini` 文件的具体名称。例如，如果格式文件由 `xelatex.ini` 生成（对应的格式文件一定为 `xelatex.fmt`），则此方法应当返回 `xelatex.ini`。
    func getIniFileName(for format: CompileFormat) -> String
    
    
    /// 编译 `*.ini` 文件并获取编译得到的 `fmt` 文件的数据。
    ///
    /// 实现本协议的类必须实现本方法以实现编译 `ini` 文件为 `fmt` 文件的功能。
    ///
    /// 格式文件一般存在于 `texlive` 源文件 `TEXMF` 根目录的 `/texmf-dist/tex/generic/tex-ini-files/` 文件夹以及 `/texmf-dist/tex/latex/latexconfig/` 文件夹中。
    ///
    /// 编译格式文件时必须使用完整版本的 `texlive` 源文件目录，否则编译很可能失败。
    ///
    /// 本方法一般仅在开发阶段进行调用，用于生成与 `texlive` 版本相对应的稳定的 `fmt` 文件。在生成了 `fmt` 文件后，一般将其保存至 `texlive` 的 `TEXMF` 根目录的相应位置。
    ///
    /// 如果想查看 `TeX` 引擎内部的输出，可以通过 Safari 浏览器去检查正在开发的应用程序的相关页面。
    ///
    /// - Parameter ini: 初始化时指定的格式文件的 `URL`，在访问时需要保证该 `URL` 已经具有了访问权限。
    /// - Returns: 返回编译得到的 `fmt` 文件的数据。
    func compileFMT(ini iniFileURL: URL) async throws -> Data
    
    
    /// 编译某个 `TeX` 文件并且获取编译得到的结果数据。
    ///
    /// 实现本协议的类必须实现本方法以实现编译 `tex` 文件为 `pdf` 文件的功能。
    ///
    /// > 实现本协议的类在实现本方法时必须检查传入的 `URL` 对应的 `tex` 文件是否可读，当不可读取时必须抛出 `CompileTeXError.texFileNotFound` 错误。
    ///
    /// - Parameter format: 编译时指定的格式。实现本方法时需要根据不同的格式文件采用不同的编译方法。
    /// - Parameter texFileURL: 被编译的 `tex` 文件的目录所在的 `URL`。
    func compileTeX(by format: CompileFormat, tex texFileURL: URL) async throws -> CompileResult
    
    
    /// 判断某个来自 `texlive` 的资源文件是否可被当做编译源文件
    ///
    /// - Parameter texResourceURL: 想要被判断的编译源文件的 `URL`。
    /// - Returns: 实现本协议的类应当返回一个 `Bool` 值，该值表明了参数对应的文件是否可以被当做编译源文件。
    nonisolated func checkTeXResource(for texResourceURL: URL) -> Bool
}

//MARK: - TeXEngine 协议的一些默认实现
extension TeXEngineProvider {
    
    /// 编译适合于当前引擎的格式文件
    ///
    /// 编译格式文件时必须使用完整版本的 `texlive` 源文件目录，否则编译很可能失败。
    ///
    /// 本方法一般仅在开发阶段进行调用，用于生成与 `texlive` 版本相对应的稳定的 `fmt` 文件。在生成了 `fmt` 文件后，一般将其保存至 `texlive` 的 `TEXMF` 根目录的相应位置。
    ///
    /// 如果想查看 `TeX` 引擎内部的输出，可以通过 Safari 浏览器去检查正在开发的应用程序的相关页面。
    ///
    /// - Parameter for: 指定的格式类型，可以在 `plain-tex` 和 `latex` 中进行选择。
    /// - Parameter target: 格式文件生成后 `fmt` 文件的写入目标文件夹，调用本方法时必须已经取得对此文件夹的访问权限。
    /// - Returns: 返回编译得到的 `fmt` 文件的数据。
    public func compileFMT(for formatType: CompileFormat, target targetDirectoryURL: URL) async throws  {
        let url = try await self.getIniFileURL(for: formatType)
        let fmtData = try await self.compileFMT(ini: url)
        try? FileManager.default.createDirectory(at: targetDirectoryURL, withIntermediateDirectories: true)
        let targetFormatURL = targetDirectoryURL.appendingComponent(
            url.deletingPathExtension().lastPathComponent + ".fmt"
        )
        if !FileManager.default.createFile(atPath: targetFormatURL.versionPath, contents: fmtData) {
            throw CompileFormatError.compileFailured
        }
    }
    
    
    /// 使用当前引擎编译 `TeX` 文档
    ///
    /// > 遵循本协议的类均应当实现 ``compileTeX(by:tex:)`` 方法。
    ///
    /// - Parameter by: 指定编译格式。包含了 `plain-tex` 格式和 `latex` 格式。目前所有的 TeX 引擎均支持这两种格式。
    ///
    /// - Parameter tex: `TeX` 文件的 `URL`，该
    public func compileTeX(by formatType: CompileFormat, tex texFileURL: URL, target targetDirectoryURL: URL?) async throws {
        let result = try await self.compileTeX(by: formatType, tex: texFileURL)
        await withCheckedContinuation { continuation in
            let texFileDirectory = texFileURL.deletingLastPathComponent()
            let baseName = texFileURL.deletingPathExtension().lastPathComponent
            let pdfFileName = baseName + ".pdf"
            let synctexFileName = baseName + ".synctex"
            let logFileName = baseName + ".log"
            let pdfURL = targetDirectoryURL?.appendingComponent(pdfFileName) ?? texFileDirectory.appendingComponent(pdfFileName)
            let synctexURL = targetDirectoryURL?.appendingComponent(synctexFileName) ?? texFileDirectory.appendingComponent(synctexFileName)
            let logURL = targetDirectoryURL?.appendingComponent(logFileName) ?? texFileDirectory.appendingComponent(logFileName)
            FileManager.default.createFile(atPath: pdfURL.versionPath, contents: result.pdf)
            FileManager.default.createFile(atPath: synctexURL.versionPath, contents: result.synctex?.data(using: .utf8))
            FileManager.default.createFile(atPath: logURL.versionPath, contents: result.log.data(using: .utf8))
            continuation.resume()
            return
        }
        
    }
    
    /// 返回某个格式对应的格式文件的文件名
    ///
    /// 返回的文件名必定以 `.fmt` 为后缀。
    ///
    /// - Parameter format: 想要查询格式文件名的格式。
    /// - Returns: 返回参数指定的格式文件对应的格式名称。
    public func getFormatFileName(for format: CompileFormat) -> String {
        let result = getIniFileName(for: format).lowercased()
        assert(result.hasSuffix(".ini"), "实现协议方法 getIniFileName(for:) 时返回值必须以 .ini 为后缀!")
        return ((result as NSString).deletingPathExtension as String) + ".fmt"
    }
    
    /// 返回某个格式对应的格式文件的 `URL`
    ///
    /// 将使用文件查询器进行查询。如果无法查询到格式文件将抛出错误。
    ///
    /// > 可能抛出错误，具体抛出的错误在 `CompileFormatError` 中定义。
    /// - Returns: 返回查询到的格式文件的 `URL`。
    public func getIniFileURL(for format: CompileFormat) async throws -> URL {
        guard let fileQuerier = self.fileQuerier else {
            throw CompileFormatError.engineNotReady
        }
        let iniFileURL = await fileQuerier.search(
            for: self.getIniFileName(for: format),
            with: .kpse_tex_format
        )
        guard case .texlive(let url) = iniFileURL else {
            throw CompileFormatError.iniFileNotFound
        }
        return url
    }
    
    /// 当前引擎所支持的所有格式文件的名称
    var allFormatFileName: [(format: CompileFormat, fileName: String)] {
        CompileFormat.allCases.map {
            ($0, self.getFormatFileName(for: $0))
        }
    }
}
