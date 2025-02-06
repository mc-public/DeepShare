//
//  MainActor+Assign.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/15.
//

import Foundation

extension MainActor {
    /// Returns a Boolean value that indicates whether the current thread is the main thread.
    ///
    /// - Returns: `true` if the current thread is the main thread, otherwise `false`.
    public nonisolated static var isMainThread: Bool {
        Thread.isMainThread
    }
    /// Assign a task to the `MainActor`.
    ///
    /// If this function is called on the `MainActor`, the provided closure will be executed immediately; if this method is called from another thread, it will dispatch the closure to be executed asynchronously on the main thread.
    ///
    /// - Parameter body: A closure executed on the `MainActor`.
    public nonisolated static func assign(_ body: sending @escaping @MainActor () -> ()) {
        if isMainThread {
            Self.assumeIsolated {
                body()
            }
        } else {
            Task { @MainActor in
                body()
            }
        }
    }
}
