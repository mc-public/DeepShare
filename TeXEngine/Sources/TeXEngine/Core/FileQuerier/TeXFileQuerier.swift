//
//  TeXFileQuerier.swift
//
//
//  Created by 孟超 on 2023/8/1.
//

import Foundation
import WebKit

//MARK: - TeXFileQueryProvider

/// 用于执行 TeX 文件查询的类
@MainActor
public class TeXFileQuerier: NSObject, FileQueryProvider {
    
    struct FileQueryInfo: Hashable {
        let fileName: String
        let format: TeXFileType
    }
    
    /// 是否启用详细日志
    ///
    /// 将该属性设置为 `true` 将使得当前类在 Xcode 的控制台中输出详细的文件查找信息。该属性在调试配置下的默认值为 `true`，在发布配置下的默认值为 `false`。
    public static var usingDetailedLog: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
    
    /// 用于查询相关 TeX 资源的文件名对应的路径的查询表
    struct QueryTable {
        var texmf_dist: TeXFileQuerier.kpse_hash_table
        var texmf_config: TeXFileQuerier.kpse_hash_table
        var texmf_var: TeXFileQuerier.kpse_hash_table
        var allCases: [TeXFileQuerier.kpse_hash_table] {
            [self.texmf_dist, self.texmf_var, self.texmf_config]
        }
    }
    
    /// 当前查询器所对应的引擎
    public weak var texEngine: TeXEngineProvider?
    
    /// 当前对应的查询表的类型
    typealias kpse_hash_table = Dictionary<String, [URL]>
    
    /// 查询过程中可能出现的错误
    public enum QueryError: Error {
        /// 读取 `ls-R` 文件数据失败
        ///
        /// 此时 `texlive` 资源的 `ls-R` 文件不存在。
        case dataReadFailure
    }
    
    /// 当前查找过程中使用的 `texlive` 静态资源
    public var texliveResources: TeXResources
    /// 编译时动态读取的资源文件夹的 `URL`
    ///
    /// 在查找文件时将动态读取这里的每一个文件夹。
    ///
    /// - Warning: 预先假设这里的文件不会过多，否则会影响性能。该列表中的 `URL` 必须指代磁盘中有完全访问权限的有效 `URL`。
    public var dynamicSearchResources: [URL]
    /// 编译时指定的 `tex` 主文件所在的文件夹
    ///
    /// 实质上是 `TeX` 的工作目录。用于进行相对路径搜索。
    public var texProjectDirectory: URL?
    /// texlive 静态资源的查询表
    private var texliveQueryTable: QueryTable!
    /// 当前使用的字体查询器
    ///
    /// 该属性仅对 `XeTeX` 引擎有用，当 `XeTeX` 初始化当前类时将自动加载此属性。
    private lazy var fontQuerier: TeXFontQuerier = .init(fileQuerier: self)
    /// 当前使用的常规文件查询器
    ///
    /// 该属性对于任何 `TeX` 引擎均有用
    private lazy var regularQuerier: TeXRegularQuerier = .init(fileQuerier: self)
    
    /// 初始化文件查询器
    ///
    /// - Parameter texlive: `texlive` 的 TEXMF 根目录对应的文件夹的 `URL`。该目录中必须包含 `texmf-dist` 等文件夹，否则会抛出错误。
    public init(texlive texmfRootDirectory: URL, engine: TeXEngineProvider) async throws {
        let resources = TeXResources.init(root: texmfRootDirectory)
        self.texliveResources = resources
        self.dynamicSearchResources = []
        self.texEngine = engine
        super.init()
        let time_1 = CFAbsoluteTimeGetCurrent()
        self.texliveQueryTable = .init(
            texmf_dist: try await self.createHashTable(at: resources.texmf_dist),
            texmf_config: try await self.createHashTable(at: resources.texmf_config),
            texmf_var: try await self.createHashTable(at: resources.texmf_var)
        )
        if engine.engineType == .xetex {
            _ = fontQuerier /* lazy loading */
        }
        await self.fontQuerier.loadFontCache()
        let time_2 = CFAbsoluteTimeGetCurrent()
        if Self.usingDetailedLog {
            print("[TeXEngine][TeXFileQuerier][\(#function)] 用时:\(time_2 - time_1)")
        }
    }
    
    /// 重设 `texlive` 的对应资源目录
    ///
    /// - Parameter texlive: `texlive` 发行版的 `TEXMF` 根目录对应的文件夹的 `URL`。该目录中必须包含 `texmf-dist` 等文件夹，否则会抛出错误。
    @available(*, deprecated)
    public func setResources(texlive texmfRootDirectory: URL) async throws {
        let resources = TeXResources.init(root: texmfRootDirectory)
        self.texliveResources = resources
        self.texliveQueryTable = .init(
            texmf_dist: try await self.createHashTable(at: resources.texmf_dist),
            texmf_config: try await self.createHashTable(at: resources.texmf_config),
            texmf_var: try await self.createHashTable(at: resources.texmf_var)
        )
    }
    
    /// 检查某个 `URL` 对应的 `texlive` 源文件是否可用于当前类所服务的引擎的编译
    ///
    /// 调用本类的人一般不需要直接调用本方法。
    public func checkTeXResource(for texResourceURL: URL) -> Bool {
        return self.texEngine?.checkTeXResource(for: texResourceURL) ?? true
    }
    
    
    /// 按照文件名称搜索相应的 `URL` 值。
    ///
    /// - Parameter fileName: 想要查询的文件名称。该值仅允许为相对路径，即不以 `/` 为首字符的非空字符串。仅允许的两种合理的格式类似于 `123/dir/123.tex` 或者 `./123/dir/123.tex`。
    /// - Parameter engine: 执行搜索操作的引擎。
    public func search(for fileName: String, with type: TeXFileType) async -> FileQueryResult {
        if fileName.isEmpty {
            return .notFound
        }
        let lastFileName = (fileName as NSString).lastPathComponent.lowercased()
        if let texEngine = self.texEngine {
            for (format, url) in texEngine.dynamicFormatURL where lastFileName == texEngine.getFormatFileName(for: format) {
                guard let url else {
                    return .notFound
                }
                return .dynamic(url: url)
            }
        }
        /// 这种情况只针对字体查找
        if (fileName as NSString).isAbsolutePath {
            let url = URL(path: fileName).standardizedFileURL
            if FileManager.default.fileExists(atPath: url.versionPath) {
                //self.restoreResource(url: url)
                return .texlive(url: url)
            }
        }
        /// 如果不是绝对路径, 则不允许使用越级访问语法
        if fileName.contains("../") || fileName.contains("/./") {
            return .notFound
        }
        if let projectQueryResult = self.searchProjectResources(for: fileName, with: type) {
            return .texProject(url: projectQueryResult)
        }
        if let dynamicQueryResult = self.searchDynamicResources(for: fileName, with: type) {
            return .dynamic(url: dynamicQueryResult)
        }
        if let texResourceQueryResult = await self.searchTeXResources(for: fileName, with: type) {
            let url = texResourceQueryResult.standardizedFileURL
            //self.restoreResource(url: url)
            return .texlive(url: texResourceQueryResult)
        }
        return .notFound
    }
    
    private func restoreResource(url: URL) {
        let newPath = url.path(percentEncoded: false).replacingOccurrences(of: "Documents/texmf", with: "Documents/texmf-copied")
        let targetURL = URL(filePath: newPath)
        do {
            try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {}
        do {
            try FileManager.default.copyItem(at: url, to: targetURL)
        } catch {}
    }
    
    
}

//MARK: - Hash Query

extension TeXFileQuerier {
    
    /// 在动态资源中搜索指定的文件
    ///
    /// 虽然这里要求了相对路径，但实质上只会获取最后一个路径部分，然后再动态资源对应的文件夹中进行深度搜索。
    ///
    /// - Parameter relativePath: 想要搜索的文件的相对路径。
    /// - Parameter type: 想要搜索的 `TeX` 文件类型。
    private func searchDynamicResources(for relativePath: String, with type: TeXFileType) -> URL? {
        let fileNames = self.formatFileName(for: relativePath, with: type)
        loop1: for url in self.dynamicSearchResources {
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .nameKey]) else {
                continue loop1
            }
            loop2: for case let fileURL as URL in enumerator {
                guard let resourceValue = try? fileURL.resourceValues(forKeys: .init([.isDirectoryKey, .nameKey])) else {
                    continue loop2
                }
                for name in fileNames {
                    if resourceValue.name == name {
                        return fileURL.standardizedFileURL
                    }
                }
            }
        }
        return nil
    }
    
    
    /// 根据某个相对名称，搜索 TeX 主文件所在的文件夹对应的 `URL`。
    ///
    /// - Parameter relativeName: 相对于 TeX 主文件所在的文件夹的相对路径。
    /// - Returns: 返回一个可选的 `URL` 值，该 `URL` 值已被标准化。如果为 `nil` 则表示在主文件夹中没有搜索到对应文件，否则该 `URL` 对应的文件真实存在于磁盘。
    private func searchProjectResources(for relativePath: String, with type: TeXFileType) -> URL? {
        guard let texProjectDirectory = self.texProjectDirectory else {
            return nil
        }
        for relativePath in self.formatFileName(for: relativePath, with: type) {
            let targetURL = URL(path: relativePath, relativeTo: texProjectDirectory).standardizedFileURL
            if FileManager.default.fileExists(atPath: targetURL.versionPath) {
                return targetURL
            }
        }
        return nil
    }
    
    
    /// 在 `texlive` 资源对应的字典中搜索相关文件
    ///
    /// - Returns: 返回一个可选的 `URL` 值，该 `URL` 值已被标准化。如果为 `nil` 则表示在主文件夹中没有搜索到对应文件，否则该 `URL` 对应的文件真实存在于磁盘。
    private func searchTeXResources(for relativePath: String, with type: TeXFileType) async -> URL? {
        let resultValue: URL? = await withCheckedContinuation { checkedContinuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    let fileNames = await self.formatFileName(for: relativePath, with: type)
                    for name in fileNames {
                        loop1: for table in (await self.texliveQueryTable.allCases) {
                            guard let urls = table[name], !urls.isEmpty else {
                                continue loop1
                            }
                            loop2: for url in urls {
                                if await self.checkTeXResource(for: url)  {
                                    checkedContinuation.resume(returning: url.standardizedFileURL)
                                    return
                                } else {
                                    continue loop2
                                }
                            }
                            /* 此时我们直接返回第一个元素 */
                            checkedContinuation.resume(returning: urls[0].standardizedFileURL)
                            return
                        }
                    }
                    checkedContinuation.resume(returning: nil)
                    return
                }
            }
        }
        return resultValue
        
    }
    
    
    /// 在查询动态资源或者 `texlive` 资源时被调用，返回被格式化以后的所有可能路径值。
    ///
    /// - Parameter name: TeX 引擎请求的文件名称，该值可以是相对路径也可以是绝对路径，但无论如何都只取其最后一个路径部分。
    /// - Parameter type: 查询时指定的 `TeX` 文件类型。
    /// - Returns: 返回一个字符串数组，其中最有可能命中的名称在数组的最前面。
    private func formatFileName(for relativePath: String, with type: TeXFileType) -> [String] {
        let url = URL(path: relativePath)
        let fileName = url.lastPathComponent
        let extensionName = url.pathExtension
        let externalNames = type.suffix.map { fileName + $0 }
        if extensionName.isEmpty {
            return externalNames
        }
        return [fileName] + externalNames
    }
    
    /// baseURL: 包含 `ls-R` 文件的目录
    private func createHashTable(at dic_URL: URL) async throws -> kpse_hash_table {
        let returnValue: kpse_hash_table =
        try await withCheckedThrowingContinuation { checkedContinuation in
            DispatchQueue.global().async {
                let lsrURL = dic_URL.appendingComponent("ls-R")
                guard let fileContent = try? String(contentsOf: lsrURL) else {
                    checkedContinuation.resume(throwing: QueryError.dataReadFailure)
                    return
                }
                // 把整个字符串拆分为行以便于处理
                let dataBase = fileContent.split(whereSeparator: \.isNewline)
                var temp_dic = String()
                var base_dic = dic_URL.versionPath
                // 保证基础目录的末尾没有分隔符
                if base_dic.last == "/" {
                    base_dic.removeLast()
                }
                var hashTable = kpse_hash_table()
                loop1: for line in dataBase {
                    guard let last = line.last else {
                        continue loop1
                    }
                    var lineString = String(line)
                    if last == ":" && line.first != nil {
                        lineString.removeLast()
                        lineString.removeFirst()
                        temp_dic = base_dic + lineString
                        if temp_dic.last != "/" {
                            temp_dic.append("/")
                        }
                    } else {
                        let newURL = URL(path: temp_dic + lineString)
                        if var checkResult = hashTable[lineString] {
                            checkResult.append(newURL)
                            hashTable.updateValue(checkResult, forKey: lineString)
                        } else {
                            hashTable.updateValue([newURL], forKey: lineString)
                        }
                    }
                    
                }
                let lastCom = dic_URL.lastPathComponent
                let count = hashTable.count
                Task {
                    if await Self.usingDetailedLog {
                        print("[TeXEngine][\(Self.Type.self)][createHashTable] \(lastCom) 处的字典键数: \(count)\n")
                    }
                }
                checkedContinuation.resume(returning: hashTable)
                return
            }
        }
        
        return returnValue
        
    }
    
    /// 获取某个 `URL` 相对于其父目录的相对路径。
    ///
    /// 父目录必须实际包含了该子目录，否则会返回 `nil`。
    ///
    /// - Parameter fileURL: 想要获取相对路径的 `URL`。
    /// - Parameter directoryURL: 想要获取相对路径的 `URL` 的基础 `URL`。
    ///
    /// - Returns: 返回相对于第二个参数的相对路径。请注意，返回的第一个位置不会带有 `/`。
    static nonisolated func getRelativePath(for fileURL: URL, in directoryURL: URL) -> String? {
        let fileURL = fileURL.standardizedFileURL
        let directoryURL = directoryURL.standardizedFileURL
        if directoryURL.pathComponents.count > fileURL.pathComponents.count || fileURL.pathComponents.count <= 1 {
            return nil
        }
        for (offset, component) in directoryURL.pathComponents.enumerated() {
            if component != fileURL.pathComponents[offset] {
                return nil
            }
        }
        let resultComponents = fileURL.pathComponents[directoryURL.pathComponents.count..<fileURL.pathComponents.count]
        let newArray = Array(resultComponents)
        let string = newArray.joined(separator: "/")
        return string
    }
}

//MARK: - WKURLSchemeHandler

extension TeXFileQuerier: WKURLSchemeHandler {
    
    
    
    /// 响应请求时可能出现的错误
    enum URLTaskFail: Error {
        /// ``URL`` 解析失败
        case URLResolutionFailure
        /// 没有找到想要的文件
        case FileNotFound
        /// 文件读取失败
        case FileReadFailure
    }
    
    
    
    public nonisolated func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(Self.URLTaskFail.URLResolutionFailure)
            return
        }
        /// 判断是否为 XeTeX 字体搜索
        if let _ = urlSchemeTask.request.value(forHTTPHeaderField: "XeTeX-Font-Query-Type") {
            /* XeTeX 字体搜索 */
            Task { @MainActor in
                self.fontQuerier.searchFont(urlSchemeTask: urlSchemeTask, requestURL: url)
            }
            return
        } else if let _ = urlSchemeTask.request.value(forHTTPHeaderField: "Kpathsea-Regular-File-Query") {
            /* Kpathsea 文件查询 */
            Task { @MainActor in
                self.regularQuerier.searchFile(urlSchemeTask: urlSchemeTask, requestURL: url)
            }
        }
        
    }
    
    
    nonisolated public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
    
}


