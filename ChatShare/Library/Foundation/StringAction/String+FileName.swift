//
//  String+FileName.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/9.
//

import Foundation

extension String {
    @inlinable
    /// Get the valid Unix file name corresponding to the current string.
    ///
    /// - Parameter empty: The placeholder name used when the normalized file name is empty. If `nil`, an empty string will be returned in this case.
    func sanitizedFileName(empty: String? = nil) -> String {
        let result = self.components(separatedBy: .init(charactersIn: "/:\\?%*|\"<>"))
            .joined()
        return result.isEmpty ? (empty ?? "") : result
    }
    
    /// Check if the current file name is a valid Unix file name.
    var isSanitizedFileName: Bool {
        !self.sanitizedFileName().isEmpty
    }
}
