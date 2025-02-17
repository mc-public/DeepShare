//
//  TeXEngine+pdfTeX.swift
//
//
//  Created by 孟超 on 2024/2/17.
//

import Foundation

class PDFTeXEngineInfo: EngineInfoProvider {
    var type: EngineType {
        .pdftex
    }
    
    var supportedUnicode: Bool {
        false
    }
    
    var plainFormatURL: URL? = Bundle.module.url(forResource: "pdftex", withExtension: "fmt")
    
    var latexFormatURL: URL? = Bundle.module.url(forResource: "pdflatex", withExtension: "fmt")
    
    var htmlFileName: String {
        "pdfTeXEngine"
    }
    
    nonisolated func checkTeXResource(for texResourceURL: URL) -> Bool {
        let path = texResourceURL.versionPath
        let result = (path.contains("/tex/xetex/"))||(path.contains("/tex/latex/"))||(path.contains("/tex/generic/"))
        return result
    }
    
    func getIniFileName(for format: CompileFormat) -> String {
        switch format {
        case .latex, .biblatex:
            return "pdflatex.ini"
        case .plain:
            return "pdftex.ini"
        default:
            fatalError("[TeXEngine][\(Self.self)][Internal][\(#function)] 格式\(format)的 ini 文件查询方法尚未实现。这种情况不应出现，请联系框架开发者邮箱：3100489505@qq.com")
        }
    }
    
    
}
