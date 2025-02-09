//
//  URL+Temporary.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/9.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    
    /// Create a temporary file using the specified data and filename.
    ///
    /// - Parameter data: The data to be written to the file.
    /// - Parameter fileName: The name of the temporary file to be written. This name must be a valid Unix filename, otherwise this method will trigger an assertion. Passing `nil` indicates using a random `UUID` string.
    /// - Returns: Returns the URL of the temporarily written file. If the value is nil, it indicates that the file failed to write due to insufficient disk space.
    static func temporaryFileURL(data: Data, fileName: String? = nil, conformTo fileType: UTType) -> URL? {
        assert(fileName?.isSanitizedFileName ?? true, "[\(URL.self)][\(#function)] The file name `\(fileName ?? "")` provided is not a valid Unix file name.")
        let dir = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let url = dir.appendingPathComponent(fileName ?? UUID().uuidString, conformingTo: fileType)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileResult = FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: data)
        return fileResult ? url : nil
    }
    
    /// Create a temporary file using the specified data and filename.
    ///
    /// - Parameter data: The data to be written to the file.
    /// - Parameter fileName: The name of the temporary file to be written. This name must be a valid Unix filename, otherwise this method will trigger an assertion. Passing `nil` indicates using a random `UUID` string.
    /// - Returns: Returns the URL of the temporarily written file. If the value is nil, it indicates that the file failed to write due to insufficient disk space.
    static func temporaryFileURL(data: Data, fileName: String? = nil, conformTo fileType: UTType) async -> URL? {
        await Task.detached {
            self.temporaryFileURL(data: data, fileName: fileName, conformTo: fileType)
        }
    }
}
