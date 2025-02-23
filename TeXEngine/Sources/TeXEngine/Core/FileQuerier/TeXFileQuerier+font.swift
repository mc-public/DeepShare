//
//  TeXFileQuerier+font.swift
//
//
//  Created by 孟超 on 2023/7/26.
//

import Foundation
import CoreText
import WebKit


//MARK: - XeTeX 字体搜索的实现

/// 表示实际的字体信息的结构体
struct FontInfo: Codable {
    let path: String
    let extensionName: String
    let postScriptName: String
    let fullNames: [String]
    let familyNames: [String]
    let styleNames: [String]
    let index: Int
    
    init(path: String, extensionName: String, postScriptName: String, fullNames: [String], familyNames: [String], styleNames: [String], index: Int) {
        self.path = path
        self.extensionName = extensionName
        self.postScriptName = postScriptName
        self.fullNames = fullNames
        self.familyNames = familyNames
        self.styleNames = styleNames
        self.index = index
    }
    
    init(from cachedFontInfo: CachedFontInfo, root baseURL: URL) {
        let newPath = baseURL.standardizedFileURL.versionPath + cachedFontInfo.relativePath
        self.path = newPath
        //#if DEBUG
        //print("[TeXEngine][FontInfo]" + self.path)
        //#endif
        self.extensionName = cachedFontInfo.extensionName
        self.postScriptName = cachedFontInfo.postScriptName
        self.fullNames = cachedFontInfo.fullNames
        self.familyNames = cachedFontInfo.familyNames
        self.styleNames = cachedFontInfo.styleNames
        self.index = cachedFontInfo.index
    }
}

/// 表示在 JSON 文件中缓存的字体信息的结构体
struct CachedFontInfo: Codable {
    /// 相对于 `TEXMF` 树的根目录的相对路径
    let relativePath: String
    let extensionName: String
    let postScriptName: String
    let fullNames: [String]
    let familyNames: [String]
    let styleNames: [String]
    let index: Int
    
    init(relativePath: String, extensionName: String, postScriptName: String, fullNames: [String], familyNames: [String], styleNames: [String], index: Int) {
        self.relativePath = relativePath
        self.extensionName = extensionName
        self.postScriptName = postScriptName
        self.fullNames = fullNames
        self.familyNames = familyNames
        self.styleNames = styleNames
        self.index = index
    }
    
    init(from fontInfo: FontInfo, root baseURL: URL) {
        guard let relativePath = TeXFileQuerier.getRelativePath(for: URL(path: fontInfo.path), in: baseURL) else {
            fatalError("[TeXEngine][Internal] 无法在 baseURL: \(baseURL.versionPath) 中查找到 \(fontInfo.path) 的相对路径。这是框架的内部错误。请联系开发者邮箱：3100489505@qq.com")
        }
        self.relativePath = relativePath
        self.extensionName = fontInfo.extensionName
        self.postScriptName = fontInfo.postScriptName
        self.fullNames = fontInfo.fullNames
        self.familyNames = fontInfo.familyNames
        self.styleNames = fontInfo.styleNames
        self.index = fontInfo.index
    }
    
    
}

/// 表示一组字体信息
struct FontInfoArray: Codable {
    let infoArray: [FontInfo]
    let number: Int
    init(infoArray: [FontInfo]) {
        self.infoArray = infoArray
        self.number = infoArray.count
    }
}

/// 用于缓存 texlive 字体资源的有关信息的字体缓存映射
final class FontInfoJSONCache: Codable, @unchecked Sendable {
    private let lock = NSLock()
    /// 字体缓存映射
    typealias FontInfoCache = [String: CachedFontInfo]
    /// 字体的 PostScript 名称对应的字体缓存
    var postScriptNameCache: FontInfoCache {
        get { lock.withLock { _postScriptNameCache } }
        set { lock.withLock { _postScriptNameCache = newValue }}
    }
    /// 字体的 FullName 对应的字体缓存
    var fullNameInfoCache: FontInfoCache {
        get { lock.withLock { _fullNameInfoCache } }
        set { lock.withLock { _fullNameInfoCache = newValue }}
    }
    /// 字体的 Family 对应的字体缓存
    var familyInfoCache: [String: [CachedFontInfo]] {
        get { lock.withLock { _familyInfoCache } }
        set { lock.withLock { _familyInfoCache = newValue }}
    }
    
    
    private var _postScriptNameCache: FontInfoCache = .init()
    private var _fullNameInfoCache: FontInfoCache = .init()
    private var _familyInfoCache: [String: [CachedFontInfo]] = .init()
    
    private enum CodingKeys: String, CodingKey {
        case _postScriptNameCache, _fullNameInfoCache, _familyInfoCache
    }
    
    /// 初始化空缓存
    init() {}
    
    /// 从某个相对于 `TEXMF` 根目录的 `JSON` 文件中解析缓存数据
    init(from fileURL: URL) async throws {
        let jsonData = try Data(contentsOf: fileURL)
        await withCheckedContinuation { checkedContinuation in
            DispatchQueue.global(qos: .userInitiated).asyncUnsafe {
                let decoded = try? JSONDecoder().decode(Self.self, from: jsonData)
                self.familyInfoCache = decoded?.familyInfoCache ?? .init()
                self.fullNameInfoCache = decoded?.fullNameInfoCache ?? .init()
                self.postScriptNameCache = decoded?.postScriptNameCache ?? .init()
                checkedContinuation.resume()
            }
        }
    }
    
    /// 深度搜索指定的目录，并由此初始化缓存
    ///
    /// 初始化后所有缓存字体信息中的相对路径均相对这里给出的参数值。
    init(deepSearch searchDirectory: URL, relative relativeDirectoryURL: URL? = nil) async {
        await withCheckedContinuation { checkedContinuation in
            DispatchQueue.global().asyncUnsafe {
                guard let enumerator = FileManager.default.enumerator(at: searchDirectory, includingPropertiesForKeys: nil) else {
                    checkedContinuation.resume()
                    return
                }
                for case let fileURL as URL in enumerator {
                    guard fileURL.fontType != .none else { continue }
                    let array = CTFontDescriptor.makeArray(fileURL: fileURL)
                    for fontDes in array {
                        guard let fontInfo = TeXFontQuerier.getFontInfo(for: fontDes) else { continue }
                        let result = CachedFontInfo(from: fontInfo, root: relativeDirectoryURL ?? searchDirectory)
                        self.postScriptNameCache[result.postScriptName] = result
                        for fullName in result.fullNames {
                            self.fullNameInfoCache[fullName] = result
                        }
                        for family in result.familyNames {
                            var infos = self.familyInfoCache[family] ?? []
                            infos.append(result)
                            self.familyInfoCache[family] = infos
                        }
                    }
                }
                checkedContinuation.resume()
            }
        }
    }
    
    /// 把当前字体缓存器缓存的字体信息写入 `JSON` 文件
    func writeJSONCache(to fileURL: URL) async {
        await withCheckedContinuation { checkedContinuation in
            Task {
                let jsonData = try? JSONEncoder().encode(self)
                FileManager.default.createFile(atPath: fileURL.versionPath, contents: jsonData)
                checkedContinuation.resume()
            }
        }
    }
    
    
   
}

/// 执行字体查询的类
///
/// 此类仅供 `XeTeX` 使用，用于自动管理 `XeTeX` 的字体搜索功能。
@MainActor
class TeXFontQuerier {
    /// 当前的字体缓存器
    ///
    /// 这个类其实什么都不做。该类的数据管理的工作交由本类进行。
    var fontInfoCache: FontInfoJSONCache
    /// 当前执行字体查询的文件查询器
    weak var fileQuerier: TeXFileQuerier?
    /// 当前文件查询器维护的 `texlive` 资源
    var texliveResources: TeXResources? {
        fileQuerier?.texliveResources
    }
    /// 当前假设字体查询器的相对路径相对于的文件夹
    var relativedDirectory: URL? {
        texliveResources?.texmf_dist.standardizedFileURL
    }
    
    /// 初始化当前的字体缓存器
    init(fileQuerier: TeXFileQuerier) {
        self.fileQuerier = fileQuerier
        self.fontInfoCache = .init()
    }
    
    /// 从文件中读取字体缓存，或者从 `TEXMF` 根目录中读取字体缓存
    ///
    /// 如果没有文件，将尝试创建缓存并写入一个临时文件。
    func loadFontCache() async {
        guard let baseURL = self.relativedDirectory else {
            return
        }
        let jsonURL = baseURL.appendingComponent("font.json")
        var cache = try? await FontInfoJSONCache(from: jsonURL)
        if (cache == nil) {
            /// 重新生成缓存
            cache = await FontInfoJSONCache(deepSearch: baseURL, relative: baseURL)
            await cache?.writeJSONCache(to: jsonURL)
        }
        self.fontInfoCache = cache!
    }
    
    /// 使用给定的名称搜索字体
    func searchFont(name: String) -> FontInfo? {
        guard let baseURL = self.relativedDirectory else {
            return nil
        }
        if let info = self.fontInfoCache.postScriptNameCache[name] ?? self.fontInfoCache.fullNameInfoCache[name] {
            return .init(from: info, root: baseURL)
        }
        if let hyphIndex = name.firstIndex(of: "-"),
           name.endIndex != hyphIndex,
           name.startIndex != hyphIndex {
            let familyName = String(name[name.startIndex..<hyphIndex])
            let styleName = String(name[name.index(hyphIndex, offsetBy: 1)..<name.endIndex])
            if let infos = self.fontInfoCache.familyInfoCache[familyName] {
                for info in infos {
                    guard info.styleNames.contains(familyName),
                          info.styleNames.contains(styleName) else {
                        continue
                    }
                    let url = URL(path: info.relativePath, relativeTo: baseURL)
                    if FileManager.default.fileExists(atPath: url.versionPath) {
                        return .init(from: info, root: baseURL)
                    }
                }
            }
        }
        guard let fontDes = Self.searchSystemFont(name: name) else {
            return nil
        }
        return Self.getFontInfo(for: fontDes)
    }
    
    func searchSameFamily(for postScriptName: String) -> [FontInfo] {
        guard let baseURL = self.relativedDirectory else {
            assertionFailure("[TeXEngine][Internal]这种情况不应该发生。这是框架的内部错误。请立即联系框架开发者邮箱：3100489505@qq.com")
            return []
        }
        if let familyNames = self.fontInfoCache.postScriptNameCache[postScriptName]?.familyNames  {
            var resultValue = [FontInfo]()
            for familyName in familyNames {
                if let result =  self.fontInfoCache.familyInfoCache[familyName] {
                    let newArray = result.map {
                        FontInfo(from: $0, root: baseURL)
                    }
                    resultValue.append(contentsOf: newArray)
                }
            }
            if !resultValue.isEmpty {
                return resultValue
            }
        }
        guard let fontDes = Self.searchSystemFont(name: postScriptName) else {
            return []
        }
        return Self.getAllSameFamilyFont(for: fontDes).compactMap { Self.getFontInfo(for: $0) }
    }
    
    
    public nonisolated func searchFont(urlSchemeTask: WKURLSchemeTask, requestURL: URL) {
        Task { @MainActor in
            let setURLSchemeDidFail = {
                urlSchemeTask.didFailWithError(Self.URLTaskFail.URLResolutionFailure)
            }
            let url = requestURL
            guard let name = urlSchemeTask.request.value(forHTTPHeaderField: "XeTeX-Font-Query-Info") else {
                setURLSchemeDidFail()
                return
            }
            guard let queryType = urlSchemeTask.request.value(forHTTPHeaderField: "XeTeX-Font-Query-Type") else {
                setURLSchemeDidFail()
                return
            }
            let setURLSchemeTaskNotFound = {
                debugPrint("[TeXEngine][XeTeX.FontQuerier][format=\(queryType)]字体未找到。索取文件名：\(name)")
                let respone = URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
                urlSchemeTask.didReceive(respone)
                urlSchemeTask.didFinish()
            }
            var headerFields = [String : String]()
            var sendValue = String()
            if queryType == "Family" {
                /// 这时 name 是字体的 Postscript 名称
                let infoArray = self.searchSameFamily(for: name)
                let result = FontInfoArray(infoArray: infoArray)
                //print(result)
                if let data = try? JSONEncoder().encode(result),
                   let jsonString = String(data: data, encoding: .utf8) {
                    sendValue = jsonString
                }
            } else {
                if let fontinfo = self.searchFont(name: name) {
                    if let data = try? JSONEncoder().encode(fontinfo),
                       let jsonString = String(data: data, encoding: .utf8) {
                        sendValue = jsonString
                    }
                }
            }
            headerFields["Font-Info-Query-Result"] = sendValue
            //print(sendValue)
            guard let respones = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields) else {
                setURLSchemeTaskNotFound()
                return
            }
            urlSchemeTask.didReceive(respones)
            urlSchemeTask.didFinish()
        }
    }
    
    
    
    
}

extension TeXFontQuerier {
    /**
     使用指定的属性名与属性值进行字体搜索
     - Parameter name: 用于搜索的属性对应的值。
     - Parameter attribute: 用于搜索的属性名，该属性名对应的值必须是一个字符串。
     - Returns: 返回所有可能的、已经被正规化的字体简介对象。不保证该对象对应的资源在文件系统中真实存在。
     */
    public nonisolated static func searchSystemFont(name: String, attribute: CTFont.Attribute) -> [CTFontDescriptor] {
        let descriptor = CTFontDescriptor.make(attributes: [attribute.rawValue: name as CFString])
        let attributeSet = Set([attribute])
        return descriptor.matchingFontDescriptors(mandatoryAttributes: attributeSet)
    }
    
    
    /**
     仅使用字体名称，在 `iOS` 提供的字体管理器中进行字体搜索，并且返回最匹配的字体简介对象。
     
     按照字体的`PostScript` 名称、显示名称、字体的 `Family-Bold` 格式字体名的顺序依次进行字体查找。查找结束后返回查找结果对应的字体简介对象。我们保证返回的对象对应的资源在文件系统中真实存在。
     
     - Parameter name: 字体搜索时指定的字体的名称。
     - Returns: 返回已经被正规化后的字体简介对象，该对象即为最匹配参数指定的字体名称的字体简介对象。保证该对象在文件系统中真实存在。
     */
    public nonisolated static func searchSystemFont(name: String) -> CTFontDescriptor? {
        /* 按照 PSName 和 FullName 进行查找 */
        let keys: [CTFont.Attribute] = [.name, .displayName]
        for key in keys {
            let checked = self.searchSystemFont(name: name, attribute: key)
            guard let firstDes = checked.first else {
                continue
            }
            if firstDes.isURLReachable {
                return firstDes
            }
        }
        /* 假设字体名的格式为 `FontFamily-Style` */
        if let hyphIndex = name.firstIndex(of: "-"),
           name.endIndex != hyphIndex,
           name.startIndex != hyphIndex {
            let familyName = String(name[name.startIndex..<hyphIndex])
            let styleName = String(name[name.index(hyphIndex, offsetBy: 1)..<name.endIndex])
            let descriptors = CTFontDescriptor
                .make(attributes: [
                    CTFont.Attribute.familyName.rawValue as CFString: familyName as CFString,
                ])
                .matchingFontDescriptors(mandatoryAttributes: nil)
            for descriptor in descriptors {
                guard let fontStyleName = descriptor.copyAttribute(.styleName) as? String,
                      fontStyleName == styleName else {
                    continue
                }
                if descriptor.isURLReachable {
                    return descriptor
                }
            }
        }
        
        return nil
    }
    
    /**
     搜索某个 **已被正规化** 的字体简介对象在字体合集中对应的字体索引。
     
     这将获取某个 *正规化* 的字体简介对象对应的字体在其所在的字体集合中的字体索引。
     */
    public nonisolated static func searchSystemFontIndex(for fontDescriptor: CTFontDescriptor) -> Int {
        guard let psName = fontDescriptor.copyAttribute(.name) as? String else {
            assertionFailure("无法获取 PostScriptName")
            return 0
        }
        for (offset, descriptor) in self.getAllSameFamilyFont(for: fontDescriptor).enumerated() {
            guard psName == descriptor.copyAttribute(.name) as? String else {
                continue
            }
            return offset
        }
        return 0
    }
    
    /**
     返回与某个正规化的字体简介对象是相同字族的所有字体
     
     返回的字体将按照字体索引进行排序。
     
     - Parameter fontDescriptor: 想要查找相同字族的字体的字体简介对象。该对象必须已经被正规化。
     - Returns: 返回所有与参数对应的字体简介对象同族的字体简介对象组成的序列，其中的字体按照字体索引进行排序。
     */
    public nonisolated static func getAllSameFamilyFont(for fontDescriptor: CTFontDescriptor) -> [CTFontDescriptor] {
        guard let familyName = fontDescriptor.copyAttribute(.familyName) as? String else {
            assertionFailure("无法获取 FamilyName")
            return []
        }
        let newDescriptors = CTFontDescriptor
            .make(attributes: [CTFont.Attribute.familyName.rawValue : familyName as CFString])
            .matchingFontDescriptors(mandatoryAttributes: nil)
        return newDescriptors
    }
    
    
    
    /**
     获取某个 **正规化** 的字体简介的属性值
     
     用于和 `XeTeX` 内部引擎交互。
     
     - Parameter fontDescriptor: 正规化的字体简介对象，必须保证该对象在对应的资源在文件系统中真实存在。
     */
    public nonisolated static func getFontInfo(for fontDescriptor: CTFontDescriptor) -> FontInfo? {
        guard let url = (fontDescriptor.copyAttribute(.url) as? URL) else {
            assertionFailure("传入的字体简介对象没有维护字体文件的 URL")
            return nil
        }
        guard let psName = fontDescriptor.copyAttribute(.name) as? String else {
            assertionFailure("传入的字体简介对象没有合适的 PS 名称, 而这种情况不可能出现.")
            return nil
        }
        let index = self.searchSystemFontIndex(for: fontDescriptor)
        let fullName = fontDescriptor.copyAttribute(.displayName) as? String
        let fullName2 = fontDescriptor.copyLocalizedAttribute(.displayName).0 as? String
        let familyName = fontDescriptor.copyAttribute(.familyName) as? String
        let familyName2 = fontDescriptor.copyLocalizedAttribute(.familyName).0 as? String
        let styleName = fontDescriptor.copyAttribute(.styleName) as? String
        let styleName2 = fontDescriptor.copyLocalizedAttribute(.styleName).0 as? String
        let fullNames = [fullName, fullName2].compactMap { $0 }
        let familyNames = [familyName, familyName2].compactMap { $0 }
        let styleNames = [styleName, styleName2].compactMap { $0 }
        
        return .init(path: url.versionPath, extensionName: url.pathExtension.lowercased(), postScriptName: psName, fullNames: fullNames, familyNames: familyNames, styleNames: styleNames, index: index)
    }
    
    /// 响应请求时可能出现的错误
    private enum URLTaskFail: Error {
        /// ``URL`` 解析失败
        case URLResolutionFailure
        /// 请求头创建失败
        case HTTPRequestFailure
    }
    
    
    
}
