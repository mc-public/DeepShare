//
//  Button+Toolbar.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/8.
//

import SwiftUICore
import SwiftUI


extension Button {
    
    /// Creates a button that displays a custom system symbol.
    ///
    /// - Parameter systemImage: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    /// - Parameter action: A view that describes the purpose of the button’s action.
    init(systemImage: String, scale: Image.Scale? = nil, role: ButtonRole? = nil, action: @escaping () -> ()) where Label == AnyView {
        if let scale {
            self.init(role: role) {
                action()
            } label: {
                AnyView(
                    Image(systemName: systemImage)
                        .imageScale(scale)
                )
            }
        } else {
            self.init(role: role, action: action) {
                AnyView(
                    Image(systemName: systemImage)
                )
            }
        }
    }
    
    
    /// Creates a button that displays a custom system symbol.
    ///
    /// - Parameter systemImage: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    /// - Parameter action: A view that describes the purpose of the button’s action.
    init(systemImage: String, role: ButtonRole? = nil, action: @escaping () -> ()) where Label == Image {
        self.init(role: role) {
            action()
        } label: {
            Image(systemName: systemImage)
        }
    }
}
