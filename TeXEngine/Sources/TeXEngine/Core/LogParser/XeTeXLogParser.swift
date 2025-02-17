//
//  XeTeXLogParser.swift
//
//
//  Created by 孟超 on 2023/10/2.
//

import Foundation
import JavaScriptCore

//MARK: - 日志解析器使用的数据结构

/// 表示所有可能的 `TeX` 引擎日志解析结果的类型的枚举
public enum TeXLogParseResultType: String {
    /// 当前结果条目为排版布局警告类型
    ///
    /// 此种类型常用于表示一些 `TeX` 排版中无法放置某些 `Box` 的警告等。
    case typesetting
    /// 当前结果条目为 `Error` 类型
    ///
    /// 此种类型常用于表示一些严重影响正常排版流程的错误，如命令无效或者无法找到某些文件等。
    case error
    /// 当前结果条目为 `Warning` 类型
    ///
    /// 此种类型常用于表示一些编译警告，这些警告不至于导致编译错误，但是仍然应当展示给用户。
    case warning
}

/// 表示日志解析结果的一个条目的结构体
public struct TeXLogParseResultItem {
    /// 当前日志条目的类型
    public let type: TeXLogParseResultType
    /// 当前日志条目对应的文件的 `URL`
    public let fileURL: URL?
    /// 当前日志条目在文件中对应的行号
    public let line: Int?
    /// 当前日志条目所含的简略内容
    public let simplifyContent: String?
    /// 当前日志条目所含的所有内容
    public let content: String
}

//MARK: - 日志解析器的实现

/// 可供所有 `TeX` 引擎使用的日志解析器
///
/// 该日志解析器用于解析 `TeX` 引擎在编译 `tex` 文件时生成的日志文件（文件扩展名为 `.log`）。
public class TeXLogParser {
    
    public typealias ParseResult = Array<TeXLogParseResultItem>
    
    private var jsFileContent: String = .init()
    
    /// 当前解析器使用的 `JavaScript` 虚拟机
    ///
    /// 必须确保在本类指定的线程中进行访问，以确保线程安全。
    private lazy var jsContext = {
        let context: JSContext = JSContext()
        self.loadParser(jsFileContent, context)
        return context
    }()
    
    /// 当前解析器进行解析的队列
    private var queue: DispatchQueue = .init(label: "XeTeXLogParser_SerialQueue_\(UUID().uuidString)")
    
    /// 初始化适合于 `XeTeX` 引擎的日志解析器
    public init() {
        let bundleParserFileName = "LogParser"
        guard let jsFileURL = Bundle.module.url(forResource: bundleParserFileName, withExtension: "js") else {
            assertionFailure("[\(Self.Type.self).\(#function)] 文件不存在: \(bundleParserFileName)，这将导致日志解析器完全不可用。请尽快联系包开发者邮箱： 3100489505@qq.com")
            return
        }
        guard let jsFileContent = try? String(contentsOf: jsFileURL) else {
            assertionFailure("[\(Self.Type.self).\(#function)] 文件虽然存在但无法读取: \(bundleParserFileName)，这将导致日志解析器完全不可用。请尽快联系开发者邮箱： 3100489505@qq.com")
            return
        }
        
        self.jsFileContent = jsFileContent
    }
    
    private func loadParser(_ fileContent: String, _ context: JSContext) {
        if #available(iOS 16.4, *) {
            #if DEBUG
            self.jsContext.isInspectable = true
            #else
            self.jsContext.isInspectable = false
            #endif
        }
        context.evaluateScript(fileContent)
    }
    
    /// 表示在解析过程中所有可能错误的枚举
    public enum ParseError: Error {
        /// 当前传入的日志数据在指定编码下无法解析
        case encodingNotAvailable(encoding: String.Encoding)
        /// 解析器发生内部错误导致日志数据无法被解析
        case parserInternalError
    }
    
    
    /// 解析 `TeX` 日志数据
    ///
    /// > 此方法可能会抛出错误，所有错误均在 `ParserError` 中定义。
    ///
    /// - Parameter data: `TeX` 引擎生成的日志文件的数据。
    /// - Parameter encoding: 解析日志文件数据时使用的编码，默认为 `UTF-8` 编码。
    /// - Returns: 返回解析的最后结果。如果没有错误，将返回空列表。
    public func parse(data: Data, encoding: String.Encoding) async throws -> ParseResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ParseResult, Error>) -> Void in
            self.parse(data: data, encoding: encoding) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
    
    /// 解析 `TeX` 日志数据
    ///
    /// > 此方法的完成处理闭包应当处理解析错误时的情形，所有错误均在 `ParserError` 中定义。
    ///
    /// - Parameter data: `TeX` 引擎生成的日志文件的数据。
    /// - Parameter encoding: 解析日志文件数据时使用的编码，默认为 `UTF-8` 编码。
    /// - Parameter completionHandler: 解析完成或者解析遇到错误时执行的闭包。此闭包将在主线程上执行。
    public func parse(data: Data, encoding: String.Encoding = .utf8, completionHandler: @escaping (Result<ParseResult, ParseError>) -> ()) {
        self.queue.async {
            guard let logString = String(data: data, encoding: encoding) else {
                DispatchQueue.main.async {
                    completionHandler(.failure(.encodingNotAvailable(encoding: encoding)))
                }
                return
            }
            guard let returnValue = self.jsContext.evaluateScript("parseLog(\"\(logString.javaScriptString)\")"),
                  let backDirectory = returnValue.toDictionary()
            else {
                DispatchQueue.main.async {
                    completionHandler(.failure(.parserInternalError))
                }
                return
            }
            /// 依次处理错误和警告
            let errors = backDirectory["errors"] as? [Any] ?? []
            let warnings = backDirectory["warnings"] as? [Any] ?? []
            let typesettings = backDirectory["typesetting"] as? [Any] ?? []
            let allTypeInfos = (errors + warnings + typesettings).compactMap { (element: Any) -> TeXLogParseResultItem? in
                let element = (element as? [AnyHashable: Any]) ?? [:]
                let line = element["line"] as? Int
                let message = element["message"] as? String
                guard let level = element["level"] as? String,
                let type = TeXLogParseResultType(rawValue: level),
                let raw = element["raw"] as? String,
                let filePath = element["file"] as? String
                else {
                    return nil
                }
                let url = URL(path: filePath, relativeTo: nil).standardizedFileURL
                return TeXLogParseResultItem(type: type, fileURL: url, line: line, simplifyContent: message, content: raw)
            }
            DispatchQueue.main.async {
                completionHandler(.success(allTypeInfos))
            }
        } /* queue.async */
    }
    
}
