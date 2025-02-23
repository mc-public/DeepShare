//
//  TextArea.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    
    @ViewBuilder
    func textEditorPrompt<T>(text: String, _ prompt: String, style: T) -> some View where T: ShapeStyle {
        self
            .introspect(.textEditor, on: .iOS(.v17...)) { view in
                view.backgroundColor = .clear
            }
            .background {
                if text.isEmpty {
                    TextEditor(text: .constant(prompt))
                        .introspect(.textEditor, on: .iOS(.v17...)) { view in
                            view.backgroundColor = .clear
                        }
                        .foregroundStyle(style)
                        .disabled(true)
                }
            }
            .animation(nil, value: text)
    }
}

