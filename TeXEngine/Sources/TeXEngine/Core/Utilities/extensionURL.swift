//
//  extensionURL.swift
//  
//
//  Created by 孟超 on 2023/7/20.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    
    
    /// 当前 `URL` 对应资源的 `Mime-Type`
    ///
    /// 对于未知格式将返回 `application/octet-stream`
    public var mimeType: String {
        if let uti = UTType(filenameExtension: self.pathExtension), let result = uti.preferredMIMEType {
            return result
        } else {
            return "application/octet-stream"
        }
    }
    
    /// 当前 `URL` 适合于当前 `iOS` 版本的对应路径
    ///
    /// 在 `iOS 16.0` 及以上版本中，其指的是非百分比编码的路径；否则指的是已经被弃用的 `path` 属性。
    var versionPath: String {
        if #available(iOS 16.0, *) {
            return self.path(percentEncoded: false)
        } else {
            return self.path
        }
    }
    
    /// 使用路径初始化 `URL`。
    ///
    /// - Parameter path: 用于初始化的路径。
    init(path: String, relativeTo relativeURL: URL? = nil) {
        if #available(iOS 16.0, *) {
            self.init(filePath: path, relativeTo: relativeURL)
        } else {
            self.init(fileURLWithPath: path, relativeTo: relativeURL)
        }
    }
    
    /// 返回添加了路径组件的 `URL`。
    ///
    /// - Parameter name: 想要添加的路径组件。
    func appendingComponent(_ name: String) -> URL {
        if #available(iOS 16.0, *) {
            return self.appending(component: name)
        } else {
            return self.appendingPathComponent(name)
        }
    }
    
    /// 字体文件的可能类型
    ///
    /// 表示某个 `TrueType` 或 `OpenType` 字体文件的类型。
    enum FontFileType {
        /// 不是字体文件。
        case none
        /// 是 `TrueType` 或 `OpenType` 单个字体文件。
        ///
        /// 扩展名是 `otf` 或者 `ttf`。
        case singleFont
        /// 是 `TrueType` 或 `OpenType` 字体集合文件。
        ///
        /// 扩展名是 `otc` 或者 `ttc`。
        case fontCollection
    }
    
    /// 判断当前 `URL` 对应的文件资源是否是 `TrueType` 或者 `OpenType` 字体。
    var fontType: FontFileType {
        let extensionName = self.lastPathComponent.lowercased()
        let singleExt = [".ttf", ".otf"]
        for name in singleExt {
            if extensionName.hasSuffix(name) {
                return .singleFont
            }
        }
        let collectionExt = [".ttc", ".otc"]
        for name in collectionExt {
            if extensionName.hasSuffix(name) {
                return .fontCollection
            }
        }
        return .none
    }
    
    /// 返回操作系统的字体目录
    static var systemFontsDirectory: URL {
        URL(path: "/System/Library/Fonts/")
    }
    
}


