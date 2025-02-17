//
//  FileQueryProvider.swift
//
//
//  Created by 孟超 on 2023/7/20.
//

import Foundation
import WebKit

/// TeX 文件的查询应当遵循的协议
@MainActor
public protocol FileQueryProvider: AnyObject {
    /// 当前的查询器服务的引擎
    var texEngine: TeXEngineProvider? { get set }
    /// texlive 静态资源
    var texliveResources: TeXResources { get }
    /// 编译时动态读取的资源文件夹的 `URL`
    var dynamicSearchResources: [URL] { get set }
    /// `tex` 主文件所在的文件夹
    ///
    /// 引擎在每次执行编译时都会将该值设定为当前的 `tex` 文件所在的目录。
    var texProjectDirectory: URL? { get set }
    /// 按照文件名称搜索相应的 `URL` 值。
    ///
    /// - Parameter fileName: 当前的 `TeX` 文件的文件名称
    /// - Parameter type: 待搜索文件的格式。
    /// - Parameter engine: 调用此方法的引擎的实例。
    func search(for fileName: String, with type: TeXFileType) async -> FileQueryResult
    /// 设置 `texlive` 的对应资源目录
    ///
    /// - Parameter texlive: `texlive` 发行版的 `TEXMF` 根目录对应的文件夹的 `URL`。该目录中必须包含 `texmf-dist` 等文件夹，否则会抛出错误。
    func setResources(texlive texmfRootDirectory: URL) async throws
    /// 在搜索文件时，判断某个来自 `texlive` 的 `TeX` 源文件是否能被当前引擎使用。

    ///
    /// - Parameter for: 某个存在于 `TEXMF` 树中的 `TeX` 源文件所对应的 `URL`。
    /// - Parameter engine: 调用此方法的引擎实例。
    /// - Returns: Bool 类型，表示当前源文件是否能被当前引擎使用。
    func checkTeXResource(for texResourceURL: URL) -> Bool
 }

extension FileQueryProvider {
    
    /// 设置动态资源目录
    ///
    /// 在调用本方法时
    ///
    /// - Parameter project: 当前 `tex` 主文件所在的文件夹。
    /// - Parameter dynamic: 编译时动态读取的资源文件夹。
    func setResources(project: URL, dynamic: [URL] = []) async {
        self.texProjectDirectory = project
        self.dynamicSearchResources = dynamic
    }
    
}

/// 在文件查询器中表示文件查询结果的枚举
public enum FileQueryResult {
    /// 当前查询结果来自动态资源
    ///
    /// - Parameter url: 查询到的文件的 `URL`。
    case dynamic(url: URL)
    /// 当前查询结果来自 `tex` 工程资源
    ///
    /// - Parameter url: 查询到的文件的 `URL`。
    case texProject(url: URL)
    /// 当前查询结果来自 `texlive` 资源
    ///
    /// - Parameter url: 查询到的文件的 `URL`。
    case texlive(url: URL)
    /// 未查找到任何结果
    case notFound
}
