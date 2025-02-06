//
//  Task+Value.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/15.
//

extension Task {
    
    /// Runs the given throwing operation asynchronously as part of a new top-level task.
    @inlinable static func detached(priority: TaskPriority? = nil, _ body: sending @escaping @isolated(any) () async throws -> Success) async throws -> Success where Success: Sendable, Failure == any Error {
        try await Task.detached(priority: priority, operation: body).value
    }
    /// Runs the given throwing operation asynchronously as part of a new top-level task.
    @inlinable static func detached(priority: TaskPriority? = nil, _ body: sending @escaping @isolated(any) () async -> Success) async -> Success where Success: Sendable, Failure == Never {
        return await Task.detached(priority: priority, operation: body).value
    }
    /// Runs the given nonthrowing operation asynchronously as part of a new top-level task on behalf of the current actor.
    @inlinable static func run(priority: TaskPriority? = nil, operation: sending @escaping () async -> Success) async -> Success where Failure == Never {
        await Task(priority: priority, operation: operation).value
    }
    /// Runs the given nonthrowing operation asynchronously as part of a new top-level task on behalf of the current actor.
    @inlinable static func run(priority: TaskPriority? = nil, operation: sending @escaping () async throws -> Success) async throws -> Success where Failure == any Error {
        try await Task(priority: priority, operation: operation).value
    }
    
}
