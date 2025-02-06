//
//  URL+Security.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import Foundation

extension URL {
    /// Make the resource referenced by the url accessible to the process.
    ///
    /// - Parameter body: Closure for accessing data with a URL within a secure scope. The first parameter of the closure is the current instance, and the second parameter indicates whether access permission was successfully obtained.
    /// - Warning: Please do not call the `stopAccessingSecurityScopedResource()` method within this closure.
    @discardableResult
    func withAccessingSecurityScopedResource<T>(_ body: (URL, Bool) -> T) -> T {
        if self.startAccessingSecurityScopedResource() {
            defer {
                self.stopAccessingSecurityScopedResource()
            }
            return body(self, true)
        } else {
            return body(self, false)
        }
    }
    
    /// Make the resource referenced by the url accessible to the process.
    ///
    /// - Parameter body: Closure for accessing data with a URL within a secure scope. The first parameter of the closure is the current instance, and the second parameter indicates whether access permission was successfully obtained.
    /// - Warning: Please do not call the `stopAccessingSecurityScopedResource()` method within this closure.
    @discardableResult
    func withAccessingSecurityScopedResource<T, Err>(_ body: (URL, Bool) throws(Err) -> T) throws(Err) -> T {
        if self.startAccessingSecurityScopedResource() {
            defer {
                self.stopAccessingSecurityScopedResource()
            }
            return try body(self, true)
        } else {
            return try body(self, false)
        }
    }
}
