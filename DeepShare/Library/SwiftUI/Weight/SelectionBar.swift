//
//  SelectionBar.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/10.
//

import SwiftUI

/// The protocol which the data source for the `SelectionBar` should adhere to.
protocol SelectionBarDataResource: CaseIterable, Identifiable, Equatable, Hashable {
    /// The title of the item.
    var selectedTitle: String { get }
    /// The icon of the item.
    var itemImage: Image { get }
    /// The light color configuration of the item.
    var lightConfig: SelectionBar<Self>.Configuration { get }
    /// The dark color configuration of the item.
    var darkConfig: SelectionBar<Self>.Configuration { get }
}

extension SelectionBarDataResource {
    var lightConfig: SelectionBar<Self>.Configuration {
        SelectionBar<Self>.Configuration.defaultLight
    }
    var darkConfig: SelectionBar<Self>.Configuration {
        SelectionBar<Self>.Configuration.defaultDark
    }
}

/// A SwiftUI view for displaying a selection bar with no more than `4` items.
struct SelectionBar<T>: View where T: SelectionBarDataResource {
    
    var dataSource: [T]
    var usingCorner: Bool
    @Binding var selection: T
    
    @Environment(\.colorScheme) var colorScheme
    /// Create a selection bar with specified data source.
    ///
    /// - Parameter dataSource: The data source of the selection items.
    /// - Parameter selection: The binding value of the currently selected item.
    init(_ dataSource: [T], usingCorner: Bool = false, selection: Binding<T>) {
        self.dataSource = dataSource
        self._selection = selection
        self.usingCorner = usingCorner
    }
    
    static var unSelectedItemWidth: CGFloat { 60 }
    static var selectedItemWidth: CGFloat { 100 }
    static var barHeight: CGFloat { 40 }
    
    var barWidth: CGFloat {
        CGFloat(max(self.dataSource.count - 1, 0)) * Self.unSelectedItemWidth + Self.selectedItemWidth
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0.0) {
            ForEach(dataSource) { item in
                Button {
                    selection = item
                } label: {
                    tabItem(item: item, isActive: (selection == item))
                }
            }
        }
        
        .frame(minWidth: barWidth, maxWidth: usingCorner ? barWidth : .infinity, minHeight: Self.barHeight, maxHeight: Self.barHeight, alignment: .center)
        .background(Material.ultraThick, ignoresSafeAreaEdges: .horizontal)
        .withCondition {
            if usingCorner { $0.clipShape(.rect(cornerRadius: 13)) } else { $0 }
        }
        .shadow(radius: 0.5)
        .animation(.default, value: selection)
    }
    
    @ViewBuilder
    private func tabItem(item: T, isActive: Bool) -> some View {
        let colorConfig = (colorScheme == .dark) ? item.darkConfig : item.lightConfig
        HStack(alignment: .center, spacing: 3) {
            Spacer()
            item.itemImage
                .renderingMode(.template)
                .foregroundColor(isActive ? colorConfig.selectedImageColor : colorConfig.unselectedImageColor)
                .padding(.trailing, 5)
            if isActive {
                Text(item.selectedTitle)
                    .font(.system(size: 13))
                    .fontWidth(.standard)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(colorConfig.selectedTextColor)
            }
            Spacer()
        }
        
        .frame(minWidth: isActive ? Self.selectedItemWidth : Self.unSelectedItemWidth, maxWidth: isActive ? .infinity : Self.unSelectedItemWidth, minHeight: Self.barHeight, maxHeight: Self.barHeight)
        .background(isActive ? colorConfig.selectedBackgroundColor : colorConfig.unselectedBackgroundColor, ignoresSafeAreaEdges: .horizontal)
    }

    struct Configuration {
        var selectedTextColor: Color
        var selectedImageColor: Color
        var unselectedImageColor: Color
        var selectedBackgroundColor: Color = .cyan.opacity(0.2)
        var unselectedBackgroundColor: Color = .clear
        
        static var defaultDark: Self {
            Self(selectedTextColor: .white, selectedImageColor: .white, unselectedImageColor: .gray)
        }
        static var defaultLight: Self {
            Self(selectedTextColor: .black, selectedImageColor: .black, unselectedImageColor: .gray)
        }
    }
}
