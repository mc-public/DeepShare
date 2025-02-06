//
//  FileManager+FileAction.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/14.
//

import Foundation

extension FileManager {
    
    /// Checks whether a file corresponding to a URL with full access permissions exists.
    ///
    /// - Parameter url: The `URL` to be evaluated. Access to the resource corresponding to this `URL` is required; otherwise, this method will return `false`.
    /// - Returns: Returns whether the file exists
    func fileExists(at url: URL) -> Bool {
        return self.fileExists(atPath: url.path(percentEncoded: false))
    }
    
    /// Determine whether the file corresponding to a URL with full access permissions is a directory.
    ///
    /// - Parameter url: The URL to be evaluated. Access to the resource corresponding to this `URL` is required; otherwise, this method will return `false`.
    /// - Returns: Returns whether the file is a directory.
    func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let isExists =  self.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return isExists && isDirectory.boolValue
        
    }
    
    func withDirectoryContent(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil, options: DirectoryEnumerationOptions? = nil, _ body: (_ fileURL: URL) throws -> Void) throws {
        var urls: [URL] = []
        if let options {
            urls = try self.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
        } else {
            urls = try self.contentsOfDirectory(at: url, includingPropertiesForKeys: keys)
        }
        for fileURL in urls {
            try body(fileURL)
        }
    }
    
    func withDirectoryContent(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil, options: DirectoryEnumerationOptions? = nil, _ body: (_ fileURL: URL) -> Void) {
        try? self.withDirectoryContent(at: url, includingPropertiesForKeys: keys, options: options) { (fileURL: URL) throws -> Void in
            body(fileURL)
        }
    }
    
}
