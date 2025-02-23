//
//  Coordinator.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/14.
//

import SwiftUI

/// A container used to perform absolute position layout.
struct Frame<Content>: View where Content: View {
    
    private let width: CGFloat?
    private let height: CGFloat?
    private let alignment: Alignment
    
    struct Proxy {
        let size: CGSize
    }
    
    private let content: () -> Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.height = height
        self.alignment = alignment
        self.content = content
    }
    
    init(_ size: CGSize, alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.width = size.width
        self.height = size.height
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        content()
            .frame(width: width, height: height, alignment: alignment)
    }
}
