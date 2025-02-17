//
//  TeXEngine+compile.swift
//
//
//  Created by 孟超 on 2023/7/25.
//

import Foundation

//MARK: - 编译相关的方法的实现
extension TeXEngine {
    
    /// 判断某个来自 `texlive` 的资源文件是否可被当做编译源文件
    ///
    /// - Parameter texResourceURL: 想要被判断的编译源文件的 `URL`。
    /// - Returns: 实现本协议的类应当返回一个 `Bool` 值，该值表明了参数对应的文件是否可以被当做编译源文件。
    nonisolated public func checkTeXResource(for texResourceURL: URL) -> Bool {
        self.engineInfo.checkTeXResource(for: texResourceURL)
    }
    
    /// 当前引擎支持的格式对应的名称
    ///
    /// - Parameter format: 当前期望查询对应的格式文件的编译格式。
    ///
    /// - Returns: 应当返回 `ini` 文件的具体名称。例如，如果格式文件由 `xelatex.ini` 生成（对应的格式文件一定为 `xelatex.fmt`），则此方法应当返回 `xelatex.ini`。
    public func getIniFileName(for format: CompileFormat) -> String {
        self.engineInfo.getIniFileName(for: format)
    }
    
    /// 编译 `*.ini` 文件并获取编译得到的 `fmt` 文件的数据。
    ///
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
    public func compileFMT(ini iniFileURL: URL) async throws -> Data {
        guard let webView = self.webView, let _ = self.fileQuerier else {
            throw CompileFormatError.engineNotReady
        }
        guard self.state == .ready else {
            throw CompileFormatError.engineNotReady
        }
        NotificationCenter.default.post(name: Self.engineWillStartCompile, object: self)
        self.setState(.compiling)
        let url = iniFileURL
        let path = (url.versionPath as NSString)
            .standardizingPath
            .javaScriptString /* 只需转换参数 */
        
        self.consoleOutput = .init()
        let javaScriptCommand = "engine_INITEX(\"\(path)\")"
        let data: Data = try await withCheckedThrowingContinuation { checkedContinuation in
            DispatchQueue.main.async {
                webView.evaluateJavaScript(javaScriptCommand) { result, error in
                    if let _ = error {
                        self.setState(.crashed)
                        checkedContinuation.resume(throwing: CompileFormatError.engineCrashed)
                        return
                    }
                    guard let result = (result as? String) else {
                        self.setState(.crashed)
                        checkedContinuation.resume(throwing: CompileFormatError.engineCrashed)
                        return
                    }
                    if result == "[_EMPTY_]" {
                        self.setState(.ready)
                        checkedContinuation.resume(throwing: CompileFormatError.compileFailured)
                        return
                    }
                    Task.detached {
                        guard let encodeData = result.data(using: .utf8), let data = Data(base64Encoded: encodeData) else {
                            await self.setState(.crashed)
                            checkedContinuation.resume(throwing: CompileFormatError.engineCrashed)
                            return
                        }
                        checkedContinuation.resume(returning: data)
                    }
                }
            }
        }
        self.setState(.ready)
        return data
    }
    
    /// 编译某个 `TeX` 文件并且获取编译得到的结果数据。
    ///
    /// > 实现本协议的类在实现本方法时必须检查传入的 `URL` 对应的 `tex` 文件是否可读，当不可读取时必须抛出 `CompileTeXError.texFileNotFound` 错误。
    ///
    /// - Parameter format: 编译时指定的格式。实现本方法时需要根据不同的格式文件采用不同的编译方法。
    /// - Parameter texFileURL: 被编译的 `tex` 文件的目录所在的 `URL`。
    /// - Returns: 返回编译结果。如果引擎崩溃或者尚未加载好引擎就调用此方法，此方法将抛出错误。
    @MainActor @discardableResult
    public func compileTeX(by format: CompileFormat = .latex, tex texFileURL: URL) async throws -> CompileResult {
        guard texFileURL.pathExtension.lowercased() == "tex" else {
            throw CompileTeXError.texFileFormatNotNormal
        }
        guard FileManager.default.fileExists(atPath: texFileURL.standardizedFileURL.versionPath) else {
            throw CompileTeXError.texFileNotFound
        }
        guard let webView = self.webView, let _ = self.fileQuerier else {
            throw CompileTeXError.engineNotReady
        }
        guard self.state == .ready || self.state == .crashed else {
            throw CompileTeXError.engineNotReady
        }
        NotificationCenter.default.post(name: Self.engineWillStartCompile, object: self)
        self.setState(.compiling)
        fileQuerier?.texProjectDirectory = texFileURL.deletingLastPathComponent()
        self.consoleOutput = .init()
        let url = texFileURL
        let path = (url.versionPath as NSString)
            .standardizingPath
            .javaScriptString
        let executeJSString = switch format {
        case .plain, .latex:
            "engine_CompileTeX(\"\(path)\", \"\(self.getFormatFileName(for: format))\", true)"
        case .biblatex:
            "engine_CompileTeX_WithBibTeX(\"\(path)\", \"\(self.getFormatFileName(for: format))\")"
        default:
            fatalError("[TeXEngine][Internal][\(#function)] 格式\(format)的编译方法尚未实现却被调用。这种情况不应出现，请联系框架开发者邮箱：3100489505@qq.com")
        }
        let compileResult: CompileResult = try await withCheckedThrowingContinuation { checkedContinuation in
            DispatchQueue.main.async {
                webView.evaluateJavaScript(executeJSString) { result, error in
                    Task.detached {
                        switch format {
                        case .biblatex: await self.processBibTeXCompileResult(checkedContinuation: checkedContinuation, result: result, error: error)
                        default: /* latex or plain-tex */
                            await self.processTeXCompileResult(format: format, checkedContinuation: checkedContinuation, result: result, error: error)
                        }
                    }
                }
            }
        }
        return compileResult
    }
    
    nonisolated private func getTeXState(for result: Any?, format: CompileFormat) -> CompileResult.TeXCompileResult? {
        guard let result = result as? [String: Any],
              let state = (result["tex_state"] as? Int) else {
            #if DEBUG
            print("[TeXEngine][Internal] 无法在 WebAssembly 处获取到编译信息。请立即联系开发者邮箱 3100489505@qq.com 或者在 Github 上报告问题。")
            #endif
            return nil
        }
        guard let logString = result["log_string"] as? String else {
            return nil
        }
        guard let currentTeXState = TeXReturnValue.fromStateValue(state) else {
            #if DEBUG
            print("[TeXEngine][Internal] 无法在 WebAssembly 处获取到编译信息。请立即联系开发者邮箱 3100489505@qq.com 或者在 Github 上报告问题。")
            #endif
            return nil
        }
        switch currentTeXState {
                //TODO: Finish State Handling.
            case .fileFailured:         return nil /* 此时考虑重置引擎 */
            case .internalFailured:     return nil /* 此时一定需要重置引擎 */
            case .memoryFailured:       return nil /* 此时内存不足 需要告知用户 */
            case .noDVIOutputFailured:  return .xdvNotGenerated(log: logString)
            case .noPDFOutputFailured:  return .pdfNotGenerated(log: logString)
            default: /* succeed or normalError */
                guard let pdfString = result["pdf_base64_string"] as? String,
                      let pdfData = Data(base64Encoded: pdfString) else {
                    #if DEBUG
                    print("[TeXEngine][Internal] 无法在 WebAssembly 处获取到编译信息。请立即联系开发者邮箱 3100489505@qq.com 或者在 Github 上报告问题。")
                    #endif
                    return nil
                }
                guard let synctexString = result["synctex_string"] as? String else {
                    #if DEBUG
                    print("[TeXEngine][Internal] 无法在 WebAssembly 处获取到编译信息。请立即联系开发者邮箱 3100489505@qq.com 或者在 Github 上报告问题。")
                    #endif
                    //MARK: 这里可能不会有 SyncTeX 信息生成!
                    return nil
                }
                return currentTeXState == .succeed ? .succeed(pdf: pdfData, log: logString, synctex: synctexString) : .errorOccurred(pdf: pdfData, log: logString, synctex: synctexString)
        }
    }
    
    nonisolated private func getBibTeXState(engineType: EngineType, for result: Any?) -> CompileResult? {
        guard let result = result as? [String : Any] else { /* fatal error */
            return nil
        }
        guard let texCompileResult = self.getTeXState(for: result, format: .biblatex) else {
            return nil
        }
        guard let bibTeXState = result["bibtex_state"] as? Int else { /* 未执行 BibTeX 编译 */
            return .init(engineType: engineType, routineType: .firstCompileCompleted(texResult: texCompileResult), format: .biblatex)
        }
        if bibTeXState <= -2 { /* 无 aux 文件, 未执行 BibTeX 编译 */
            return .init(engineType: engineType, routineType: .firstCompileCompleted(texResult: texCompileResult), format: .biblatex)
        } else if bibTeXState == -1 { /* BibTeX 崩溃 */
            return nil
        }
        guard let bblString = result["bbl_string"] as? String,
              let blgString = result["blg_string"] as? String else {
            return nil
        }
        if bibTeXState >= 2 { /* BibTeX 编译时出现错误 */
            return CompileResult(engineType: engineType, routineType: .secondCompileCompleted(texResult: texCompileResult, bibResult: .errorOccurred(bbl: bblString, blg: blgString)), format: .biblatex)
        }
        /// 剩余 bibTeXState 等于 0 或 1
        if result["directly_return"] as? Bool == true { /* 直接返回相应结果 */
            return CompileResult(engineType: engineType, routineType: .secondCompileCompleted(texResult: texCompileResult, bibResult: .succeed(bbl: bblString, blg: blgString)), format: .biblatex)
        }
        /// 此时执行了第三次编译过程
        return CompileResult(engineType: engineType, routineType: .thirdCompileCompleted(texResult: texCompileResult, bibResult: .succeed(bbl: bblString, blg: blgString)), format: .biblatex)
    }
    
    
    private func processTeXCompileResult(format: CompileFormat, checkedContinuation: CheckedContinuation<CompileResult, Error>, result: Any?, error: Error?) async {
        let setCrashState = {
            checkedContinuation.resume(throwing: CompileTeXError.engineCrashed)
            self.setState(.crashed)
            NotificationCenter.default.post(name: Self.engineDidCrash, object: self)
        }
        guard let resultType = self.getTeXState(for: result, format: format) else {
            setCrashState()
            return
        }
        checkedContinuation.resume(returning: .init(engineType: self.engineType, routineType: .firstCompileCompleted(texResult: resultType), format: format))
        self.setState(.ready)
        NotificationCenter.default.post(name: Self.engineDidEndCompile, object: self)
    }
    
    private func processBibTeXCompileResult(checkedContinuation: CheckedContinuation<CompileResult, Error>, result: Any?, error: Error?) async {
        let setCrashState = {
            checkedContinuation.resume(throwing: CompileTeXError.engineCrashed)
            self.setState(.crashed)
            NotificationCenter.default.post(name: Self.engineDidCrash, object: self)
        }
        if let _ = error { /* fatal error */
            setCrashState()
            return
        }
        guard let state = self.getBibTeXState(engineType: engineType, for: result) else {
            setCrashState()
            return
        }
        checkedContinuation.resume(returning: state)
        self.setState(.ready)
        NotificationCenter.default.post(name: Self.engineDidEndCompile, object: self)
        
    }
    
}

/// 表示 TeX 返回值状态的结构体
fileprivate struct TeXReturnValue: Equatable {
    private let valueRange: Range<Int>
    /// 当前状态的返回值
    let value: Int
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.valueRange == rhs.valueRange
    }
    /// TeX 内部文件存取失败导致编译失败时抛出的错误代码
    static let fileFailured = Self(-100)
    /// TeX 内部申请内存失败导致编译失败时抛出的错误代码
    static let memoryFailured = Self(-200)
    /// TeX 出现无法解决的内部错误时抛出的错误代码
    static let internalFailured = Self(-300)
    /// TeX 引擎没有 DVI 输出时抛出的错误代码
    static let noDVIOutputFailured = Self(1000)
    /// TeX 引擎没有 PDF 输出时抛出的错误代码
    static let noPDFOutputFailured = Self(2000)
    /// TeX 引擎编译成功时的代码
    static let succeed = Self(0)
    /// TeX 引擎出现常规错误时的代码
    ///
    /// - Parameter code: 错误代码，值必须在 1...10 之间，否则会抛出运行时错误。
    static func normalError(code: Int) -> Self {
        Self(1, 10, value: code)
    }
    /// 当前错误是否是常规错误
    var isNormalError: Bool {
        (1...10).contains(self.value)
    }
    static func fromStateValue(_ value: Int) -> Self? {
        return switch value {
            case      -100: .fileFailured
            case      -200: .memoryFailured
            case      -300: .internalFailured
            case      1000: .noDVIOutputFailured
            case      2000: .noPDFOutputFailured
            case         0: .succeed
            case    1...10: Self.normalError(code: value)
            default       : nil
        }
    }
    private init(_ rawValue: Int) {
        self.valueRange = rawValue..<(rawValue + 1)
        self.value = rawValue
    }
    private init(_ min: Int, _ max: Int, value: Int) {
        self.valueRange = min..<(max + 1)
        self.value = value
        assert(self.valueRange.contains(value))
    }
}
