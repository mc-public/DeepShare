//
//  File.swift
//  
//
//  Created by 孟超 on 2024/2/8.
//

import Foundation

/// 使用各种格式编译 `TeX` 文件的编译结果
public struct CompileResult {
    
    public enum BibTeXCompileResult {
        case succeed(bbl: String, blg: String)
        case errorOccurred(bbl: String, blg: String)
    }
    
    /// 产生当前编译结果的 `TeX` 引擎的类型
    public let engineType: EngineType
    /// 当前编译结果中的 `TeX` 编译结果
    public var texResult: TeXCompileResult {
        self.routineType.texResult
    }
    /// 当前编译结果中的 `BibTeX` 编译结果
    ///
    /// 该值可能为 `nil`。值为 `nil` 时表示编译过程中未执行 `BibTeX` 编译（可能是由于根本没有指定使用 `BibTeX` 或者在使用 `BibTeX` 时第一次编译失败）。
    public var bibTeXResult: BibTeXCompileResult? {
        self.routineType.bibResult
    }
    /// 表示当前编译结果的类型的枚举实例
    public let routineType: CompileRoutineResult
    /// 当前编译结果对应的编译格式
    public let format: CompileFormat
    /// 当前编译结果对应的 `pdf` 数据
    public var pdf: Data? {
        switch self.texResult {
        case .xdvNotGenerated, .pdfNotGenerated:
            nil
        case .errorOccurred(let pdf, _, _):
            pdf
        case .succeed(let pdf, _, _):
            pdf
        }
    }
    
    /// 当前编译结果对应的 `TeX` 日志数据
    public var log: String {
        switch self.texResult {
        case .xdvNotGenerated(let log):
            log
        case .pdfNotGenerated(let log):
            log
        case .errorOccurred(_, let log, _):
            log
        case .succeed(_, let log, _):
            log
        }
    }
    
    
    /// 当前编译结果对应的 `BibTeX` 日志数据
    ///
    /// 该值可能为 `nil`，表示未使用 BibTeX 编译。
    public var blg: String? {
        guard let bibTeXResult = self.bibTeXResult else {
            return nil
        }
        return switch bibTeXResult {
        case .succeed(_, let blg):
            blg
        case .errorOccurred(_, let blg):
            blg
        }
    }
    
    /// 当前编译结果对应的 `BibTeX` 缓存数据
    ///
    /// 该值可能为 `nil`，表示未使用 `BibTeX` 编译。
    public var bbl: String? {
        guard let bibTeXResult = self.bibTeXResult else {
            return nil
        }
        return switch bibTeXResult {
        case .succeed(let bbl, _):
            bbl
        case .errorOccurred(let bbl, _):
            bbl
        }
    }
    
    
    /// 当前编译结果对应的 `synctex` 数据
    ///
    /// 该值可能为 `nil`，表示编译过程中未生成有效的 `synctex` 数据。
    public var synctex: String? {
        switch self.texResult {
        case .xdvNotGenerated, .pdfNotGenerated:
            nil
        case .errorOccurred(_, _, let synctex):
            synctex
        case .succeed(_, _, let synctex):
            synctex
        }
    }
    
    /// 表示在整个编译例程中 `TeX` 编译结果的枚举
    ///
    /// 仅包含 `TeX` 引擎的编译结果信息。
    public enum TeXCompileResult {
        /// 未生成 `xdv` 文件
        ///
        /// 该情形仅针对 `XeTeX` 引擎有效。对于 `pdfTeX` 引擎，该情形无效。
        ///
        /// - Parameter log: 编译过程中生成的日志文件数据。
        case xdvNotGenerated(log: String)
        /// 虽然生成了 `xdv` 文件，但是未生成 `pdf` 文件。
        ///
        /// - Parameter log: 编译过程中生成的日志文件数据。
        case pdfNotGenerated(log: String)
        /// 虽然生成了 `xdv` 与 `pdf` 文件，但是编译过程中出现了错误。
        ///
        /// - Parameter pdf: 编译过程中生成的 `pdf` 文件的数据。
        /// - Parameter log: 编译过程中生成的日志文件的数据。
        /// - Parameter synctex: 编译过程中生成的 `synctex` 文件的数据。
        case errorOccurred(pdf: Data, log: String, synctex: String?)
        /// 编译成功结束且得到了 `xdv` 与 `pdf` 文件
        ///
        /// - Parameter pdf: 编译过程中生成的 `pdf` 文件的数据。
        /// - Parameter log: 编译过程中生成的日志文件的数据。
        /// - Parameter synctex: 编译过程中生成的 `synctex` 文件的数据。
        case succeed(pdf: Data, log: String, synctex: String?)
    }
    
    /// 表示在整个编译例程的编译结果的枚举
    ///
    /// 该结构体对于任何引擎均适用。
    ///
    /// - Note: 请注意，对于 `CompileFormat.latex` 编译格式，该枚举只会出现第一种情形，即 `.firstCompileCompleted(texResult: TeXCompileResult)`。
    public enum CompileRoutineResult {
        /// 第一次编译时出现错误
        ///
        /// 此时后续的编译过程都没有进行。
        case firstCompileCompleted(texResult: TeXCompileResult)
        /// 第二次编译时出现错误
        ///
        /// 即 BibTeX 编译失败。
        case secondCompileCompleted(texResult: TeXCompileResult, bibResult: BibTeXCompileResult)
        /// 第三次编译时出现错误
        ///
        /// 此时已经执行 BibTeX 编译。
        case thirdCompileCompleted(texResult: TeXCompileResult, bibResult: BibTeXCompileResult)
        
        var texResult: TeXCompileResult {
            switch self {
            case .firstCompileCompleted(let texResult):
                texResult
            case .secondCompileCompleted(let texResult, _):
                texResult
            case .thirdCompileCompleted(let texResult, _):
                texResult
            }
        }
        
        var bibResult: BibTeXCompileResult? {
            switch self {
            case .firstCompileCompleted:
                nil
            case .secondCompileCompleted(_, let bibResult):
                bibResult
            case .thirdCompileCompleted(_, let bibResult):
                bibResult
            }
        }
    }
    
    
}
