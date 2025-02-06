//
//  Observable+Binding.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/10.
//

import Observation
import SwiftUI

#if compiler(<6.1)
extension ReferenceWritableKeyPath: @unchecked @retroactive Sendable where Value: Sendable, Root: Sendable {}
#endif

extension Observable where Self: AnyObject & Sendable {
    
    /// Gets the binding for a readable and writable property that is comparable in type.
    ///
    /// Usage:
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @Environment(ViewModel.self) var model
    ///     var body: some View {
    ///         Toggle("Switch", isOn: model.binding(for: \.isOn))
    ///     }
    /// }
    /// ```
    ///
    /// Updates the property's value only when the actual value of the property changes.
    /// 
    /// - Parameter keypath: The Keypath corresponding to the property for which you want to get the binding.
    /// - Parameter animation: The animation used when changing the value of the bound property.
    /// - Parameter onChange: A closure executed after the value is actually modified. The default value is false. The closure will not trigger any animations.
    @inlinable nonisolated func binding<T>(for keypath: ReferenceWritableKeyPath<Self, T>, animation: Animation? = .default, onChange: (@Sendable (T) -> ())? = nil) -> Binding<T> where T: Equatable & Sendable {
        Binding<T> {
            self[keyPath: keypath]
        } set: { [weak self] (newValue) in
            if !MainActor.isMainThread {
                print("[\(#file)][\(#function)] Warning: Access binding value from a background-thread. This may cause data-race risk.")
            }
            if newValue != self?[keyPath: keypath] {
                if let animation {
                    withAnimation(animation) {
                        self?[keyPath: keypath] = newValue
                    }
                } else {
                    self?[keyPath: keypath] = newValue
                }
                onChange?(newValue)
            }
        }
    }
    
    @inlinable func binding<T>(for keypath: ReferenceWritableKeyPath<Self, T?>, defaultValue: T, animation: Animation? = .default, onChange: (@Sendable (T) -> ())? = nil) -> Binding<T> where T: Equatable & Sendable {
        Binding<T> {
            self[keyPath: keypath] ?? defaultValue
        } set: { [weak self] (newValue) in
            if newValue != self?[keyPath: keypath] {
                if let animation {
                    withAnimation(animation) {
                        self?[keyPath: keypath] = newValue
                    }
                } else {
                    self?[keyPath: keypath] = newValue
                }
                onChange?(newValue)
            }
        }
    }
}
