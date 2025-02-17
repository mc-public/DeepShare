//
//  XeTeXEngineInfo.swift
//
//
//  Created by 孟超 on 2024/2/17.
//

import Foundation

class XeTeXEngineInfo: EngineInfoProvider {
    
    var type: EngineType {
        .xetex
    }
    
    var supportedUnicode: Bool {
        true
    }
    
    var plainFormatURL: URL? = Bundle.module.url(forResource: "xetex", withExtension: "fmt")
    
    var latexFormatURL: URL? = Bundle.module.url(forResource: "xelatex", withExtension: "fmt")
    
    var htmlFileName: String {
        "XeTeXEngine"
    }
    
    nonisolated func checkTeXResource(for texResourceURL: URL) -> Bool {
        let path = texResourceURL.versionPath
        let result = (path.contains("/tex/xetex/"))||(path.contains("/tex/xelatex/"))||(path.contains("/tex/latex/"))||(path.contains("/tex/generic/"))
        return result
    }
    
    func getIniFileName(for format: CompileFormat) -> String {
        switch format {
        case .latex, .biblatex:
            return "xelatex.ini"
        case .plain:
            return "xetex.ini"
        default:
            fatalError("[TeXEngine][\(Self.self)][Internal][\(#function)] 格式\(format)的 ini 文件查询方法尚未实现。这种情况不应出现，请联系框架开发者邮箱：3100489505@qq.com")
        }
    }
    
    
}
