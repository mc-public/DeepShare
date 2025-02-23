//
//  View+Keyboard.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/13.
//

import Foundation
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    
    /// Disable the external keyboard and Apple Pencil shortcut bar for a specific text view.
    ///
    /// Attach this modifier to the `TextField` or `TextEditor` to disable the display of the keyboard shortcut bar when using an external keyboard connected to the iPad.
    @MainActor @ViewBuilder
    func keyboardShortcutBarDisabled() -> some View {
        self.introspect(.textEditor, on: .iOS(.v17...), customize: { textEditor in
            textEditor.inputAssistantItem.leadingBarButtonGroups = []
            textEditor.inputAssistantItem.trailingBarButtonGroups = []
            textEditor.inputAccessoryView = nil
            textEditor.autocorrectionType = .no
            textEditor.autocapitalizationType = .none
        })
        .introspect(.textField, on: .iOS(.v17...), customize: { textField in
            textField.inputAssistantItem.leadingBarButtonGroups = []
            textField.inputAssistantItem.trailingBarButtonGroups = []
            textField.inputAccessoryView = nil
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        })
    }
    
    @MainActor
    func resignKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
