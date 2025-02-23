//  - ** Public Domain ** -
//
//  PlatformView.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/6.
//

import Foundation
import SwiftUI

@MainActor
fileprivate let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom

/// A type that represents part of your app's user interface and provides
/// modifiers that you use to configure views, and adapt different views automatically based on whether the current operating system is iPadOS (Mac Catalyst) or iOS.
///
/// You create custom views by declaring types that conform to the `View`
/// protocol. Implement the required ``iPhoneBody-swift.property`` and ``iPadBody-swift.property`` computed
/// property to provide the content for your custom view.
protocol PlatformView: View {
    /// The type of view representing the body of this view for iOS.
    associatedtype IPhoneBody: View
    /// The type of view representing the body of this view for iPadOS or Mac Catalyst.
    associatedtype IPadBody: View
    
    /// The content and behavior of the view for iOS.
    @ViewBuilder @MainActor
    var iPhoneBody: Self.IPhoneBody { get }
    /// The content and behavior of the view for iPadOS.
    @ViewBuilder @MainActor
    var iPadBody: Self.IPadBody { get }
}


extension PlatformView {
    @ViewBuilder @MainActor
    var iPhoneBody: some View {
        Spacer()
    }
    @ViewBuilder @MainActor
    var iPadBody: some View {
        Spacer()
    }
    
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    @ViewBuilder @MainActor
    var body: some View {
        if userInterfaceIdiom == .pad || userInterfaceIdiom == .mac {
            self.iPadBody
        } else {
            self.iPhoneBody
        }
    }
}


