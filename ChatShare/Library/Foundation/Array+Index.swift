//
//  Array+Index.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/16.
//

extension Array {
    
    /// Removes all an element in this array.
    ///
    /// Use this method to remove an element in a collection.
    /// - Parameter element: Elements to be removed.
    @inlinable
    public mutating func removeAll(of element: Element) where Element: Equatable {
        self.removeAll { $0 == element }
    }
    
    @inlinable
    public func filter<T>(_ path: KeyPath<Element, T>, _ value: T) -> Self where T: Equatable {
        self.filter { element in
            element[keyPath: path] == value
        }
    }
    
    @inlinable
    public func firstIndex<T>(_ path: KeyPath<Element, T>, _ value: T) -> Self.Index? where T: Equatable {
        self.firstIndex { element in
            element[keyPath: path] == value
        }
    }
    
    @inlinable
    public func lastIndex<T>(_ path: KeyPath<Element, T>, _ value: T) -> Self.Index? where T: Equatable {
        self.lastIndex { element in
            element[keyPath: path] == value
        }
    }
    
    @inlinable
    public mutating func removeAll<T>(_ path: KeyPath<Element, T>, _ value: T) where T: Equatable {
        self.removeAll { element in
            element[keyPath: path] == value
        }
    }
    
}
