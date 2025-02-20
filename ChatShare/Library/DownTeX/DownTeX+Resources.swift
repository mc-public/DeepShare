//
//  DownTeX+Resources.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

import Foundation
import Zip
import SwiftUI

extension DownTeX {
    internal class Resources {
        /// The total `DownTeX` package `URL`.
        static var TotalBundle: URL {
            guard let allBundle = Bundle.main.url(forResource: "DownTeX", withExtension: "bundle") else { fatalError("[\(Resources.self)][\(#function)] Cannot load Resource file.")}
            return allBundle
        }
        /// The Pandoc bundle `URL`.
        static var PandocResource: URL {
            let target = TotalBundle.appending(path: "Pandoc.bundle")
            assert(FileManager.default.fileExists(at: target), "[\(Resources.self)][\(#function)] Cannot load Resource file.")
            return target
        }
        /// The `HTML` file about the Pandoc-JavaScript module.
        static var PandocHTMLResource: URL {
            let target = PandocResource.appending(path: "pandoc.html")
            assert(FileManager.default.fileExists(at: target), "[\(Resources.self)][\(#function)] Cannot load Resource file.")
            return target
        }
        /// The `TeXMF` resources `URL`.
        static var TeXResources: URL {
            URL.libraryDirectory.appending(path: "texmf")
        }
        /// The `TeXMF` zip-package `URL`.
        private static var TeXBundleResource: URL {
            let target = TotalBundle.appending(path: "texmf.zip")
            assert(FileManager.default.fileExists(at: target), "[\(Resources.self)][\(#function)] Cannot load Resource file.")
            return target
        }
        /// Indicates whether all resources are currently available.
        ///
        /// Default is `false`. You need to call `prepareResources()` before using all resources.
        @AppStorage("\(DownTeX.self)_TeXMF_State")
        static private(set) var isResourcesReady: Bool = false
        /// Load all resources.
        ///
        /// - Returns: A Boolean value indicating whether the resource decompression was successful.
        static func prepareResources() -> Bool {
            do {
                try Zip.unzipFile(TeXBundleResource, destination: TeXResources, overwrite: true, password: nil)
                Self.isResourcesReady = true
                return true
            } catch {
                try? FileManager.default.removeItem(at: TeXResources)
                Self.isResourcesReady = false
                return false
            }
        }
    }
}
