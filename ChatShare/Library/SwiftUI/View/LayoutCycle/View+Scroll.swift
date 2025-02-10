//
//  View+Scroll.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/10.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    func scrollIndicatorsStyle(_ style: UIScrollView.IndicatorStyle) -> some View {
        self.introspect(.scrollView, on: .iOS(.v17...), customize: { scrollView in
            scrollView.indicatorStyle = .black
        })
    }
}
