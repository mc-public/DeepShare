//
//  MenuPicker.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/6.
//

import SwiftUI

public struct MenuPickerContent<Item: Identifiable & Equatable, ItemLabel: View>: View {
    private var source: [Item]
    @Binding private  var selectedItem: Item
    private var itemLabel: (Item) -> ItemLabel
    
    public init(_ source: [Item], selectedItem: Binding<Item>, @ViewBuilder label: @escaping (Item) -> ItemLabel) {
        self.source = source
        self._selectedItem = selectedItem
        self.itemLabel = label
    }
    
    public var body: some View {
        ForEach(source) { item in
            Button {
                self.selectedItem = item
            } label: {
                HStack {
                    itemLabel(item)
                    Spacer()
                    if item == selectedItem {
                        Image(systemName: "checkmark")
                    } else {
                        Image(systemName: "checkmark")
                            .hidden()
                    }
                }
            }
        }
    }
}

public struct MenuPicker<Item: Identifiable & Equatable, ItemLabel: View, MenuLabel: View>: View {
    private var source: [Item]
    @Binding private  var selectedItem: Item
    private var itemLabel: (Item) -> ItemLabel
    private var menuLabel: () -> MenuLabel
    
    public init(source: [Item], selectedItem: Binding<Item>, @ViewBuilder itemLabel: @escaping (Item) -> ItemLabel, @ViewBuilder menuLabel: @escaping () -> MenuLabel) {
        self.source = source
        self._selectedItem = selectedItem
        self.itemLabel = itemLabel
        self.menuLabel = menuLabel
    }
    
    public var body: some View {
        Menu {
            MenuPickerContent(source, selectedItem: $selectedItem, label: itemLabel)
        } label: {
            menuLabel()
        }
        
    }
}
