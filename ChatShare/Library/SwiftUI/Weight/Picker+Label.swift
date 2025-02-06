//
//  Picker+Label.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/8.
//

import SwiftUI

extension Picker {
    nonisolated init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) where Label == Text, SelectionValue: Hashable, Content: View {
        self.init(" ", selection: selection, content: content)
    }
}

extension View {
    
    @ViewBuilder
    func pickerStyle<T: PickerStyle, S: PickerStyle>(compact: T, regular: S) -> some View {
        self.withHorizontalCondition { view, isRegular in
            if isRegular {
                view.pickerStyle(regular)
            } else {
                view.pickerStyle(compact)
            }
        }
    }
}
