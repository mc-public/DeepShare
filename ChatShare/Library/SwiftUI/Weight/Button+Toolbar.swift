//
//  Button+Toolbar.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/8.
//

import SwiftUICore
import SwiftUI


extension Button where Label == AnyView {
    
    /// Creates a button that displays a custom system symbol.
    ///
    /// - Parameter systemImage: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
    /// - Parameter action: A view that describes the purpose of the button’s action.
    init(systemImage: String, scale: Image.Scale? = nil, action: @escaping () -> ()) {
        if let scale {
            self.init(action: action) {
                AnyView(
                    Image(systemName: systemImage)
                        .imageScale(scale)
                )
            }
        } else {
            self.init(action: action) {
                AnyView(
                    Image(systemName: systemImage)
                )
            }
        }
    }
}
