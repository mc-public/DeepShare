//
//  TeXResources.swift
//  
//
//  Created by 孟超 on 2023/7/20.
//

import Foundation


/// 表示所有可能的 TeX 资源（主要指 texlive 所带资源）的结构体
public struct TeXResources {
    /// texlive 资源中 `texmf-dist` 文件夹的 `URL`
    public var texmf_dist: URL
    /// texlive 资源中 `texmf-var` 文件夹的 `URL`
    public var texmf_var: URL
    /// texlive 资源中 `texmf-config` 文件夹的 `URL`
    public var texmf_config: URL
    
    var allResources: [URL] {
        [
            self.texmf_dist,
            self.texmf_var,
            self.texmf_config
        ]
    }
    
    /// 初始化一个表示 TeX 资源的结构体
    ///
    /// 所有的参数都来源于实际文件系统中的  `texlive` **安装后** 的文件。
    ///
    /// - Warning: 必须保证参数中的所有文件夹都包含了 `ls-R` 文件，否则无法初始化文件查询器的查询字典。
    ///
    /// - Parameter texmf_dist: texlive 安装文件中 `texmf-dist` 文件夹对应的 `URL`。
    /// - Parameter texmf_var: texlive 安装文件中 `texmf-var` 文件夹对应的 `URL`。
    /// - Parameter texmf_config: texlive 安装文件中 `texmf-config` 文件夹对应的 `URL`。
    public init(texmf_dist: URL, texmf_var: URL, texmf_config: URL) {
        self.texmf_dist = texmf_dist
        self.texmf_var = texmf_var
        self.texmf_config = texmf_config
    }
    
    /// 初始化一个表示 TeX 资源的结构体
    ///
    /// 所有的参数都来源于实际文件系统中的  `texlive` **安装后** 的文件。
    ///
    /// - Warning: 必须保证参数所对应的文件夹的 `textmf-dist` 、`texmf-var` 和 `texmf-config` 文件夹中都包含了 `ls-R` 文件，否则无法初始化文件查询器的查询字典。
    ///
    /// - Parameter texmf_root_Directory: texlive 安装文件中 `texmf` 根目录对应的 `URL`。该文件夹中必须包含 `textmf-dist` 、`texmf-var` 和 `texmf-config` 这三个文件夹。
    public init(root texmf_root_Directory: URL) {
        if #available(iOS 16.0, *) {
            self.texmf_dist = texmf_root_Directory.appending(component: "texmf-dist")
            self.texmf_var = texmf_root_Directory.appending(component: "texmf-var")
            self.texmf_config = texmf_root_Directory.appending(component: "texmf-config")
        } else {
            self.texmf_dist = texmf_root_Directory.appendingPathComponent("texmf-dist")
            self.texmf_var = texmf_root_Directory.appendingPathComponent("texmf-var")
            self.texmf_config = texmf_root_Directory.appendingPathComponent("texmf-config")
        }
    }
}
