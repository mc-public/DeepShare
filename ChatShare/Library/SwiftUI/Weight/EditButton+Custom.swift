//
//  EditButton+Custom.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/8.
//

import SwiftUI

extension EditButton {
    /// Change the `EditButton` style to `Label`.
    ///
    /// - Parameter title: The customized title about the label.
    /// - Parameter systemImage: The customized system icon about the label. The default value is `pencil`.
    func labelStyle(_ title: Text? = nil, systemImage: String = "pencil") -> some View {
        self.buttonStyle(EditButtonLabelStyle(title: title, systemImage: systemImage))
    }
}

fileprivate struct EditButtonLabelStyle: ButtonStyle {
    var title: Text?
    var systemImage: String?
    func makeBody(configuration: Configuration) -> some View {
        Label {
            if let title {
                title
            } else {
                configuration.label
            }
        } icon: {
            Image(systemName: systemImage ?? "pencil")
        }
    }
    
    
}
