//
//  Menu+Convince.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/8.
//

import SwiftUI

extension Menu {
    
    /// Creates a menu that displays a custom system symbol.
    ///
    /// - Parameter systemImage: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    /// - Parameter action: A view that describes the purpose of the button’s action.
    init(systemImage: String, scale: Image.Scale, @ViewBuilder content: @escaping () -> Content) where Label == AnyView {
        self.init {
            content()
        } label: {
            AnyView(
                Image(systemName: systemImage)
                    .imageScale(scale)
            )
        }
    }
    
    /// Creates a menu that displays a custom system symbol.
    ///
    /// - Parameter systemImage: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    /// - Parameter action: A view that describes the purpose of the button’s action.
    init(systemImage: String, @ViewBuilder content: @escaping () -> Content) where Label == Image {
        self.init {
            content()
        } label: {
            Image(systemName: systemImage)
        }
    }
}
