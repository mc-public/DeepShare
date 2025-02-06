//
//  TextArea.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct TextArea: View {
    @Binding private var text: String
    private let prompt: String?
    private let promptColor: Color
    private let initalFocused: Bool
    @FocusState private var focusState: Bool
    
    init(text: Binding<String>, prompt: String? = nil, promptColor: Color = .gray, initalFocused: Bool = false) {
        self._text = text
        self.prompt = prompt
        self.promptColor = promptColor
        self.initalFocused = initalFocused
    }
    
    var body: some View {
        TextEditor(text: $text)
            .focused($focusState)
            .introspect(.textEditor, on: .iOS(.v17...)) { view in
                view.backgroundColor = .clear
            }
            .background {
                if self.text.isEmpty {
                    TextEditor(text: .constant(prompt ?? String()))
                        .introspect(.textEditor, on: .iOS(.v17...)) { view in
                            view.backgroundColor = .clear
                        }
                        .foregroundStyle(promptColor)
                        .disabled(true)
                }
            }
            .animation(nil, value: self.text)
            .onAppear {
                if self.text.isEmpty && self.initalFocused {
                    self.focusState = true
                }
            }
    }
}
