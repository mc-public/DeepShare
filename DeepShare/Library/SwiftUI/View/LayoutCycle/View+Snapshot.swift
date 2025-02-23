//
//  View+Snapshot.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI

extension View {
    @MainActor
    func snapshot(width: CGFloat? = nil, backgroundColor: Color = .clear) -> UIImage? {
        let controller =  UIHostingController(
            rootView: self.ignoresSafeArea()
                .frame(width: width)
                .fixedSize(horizontal: width == nil, vertical: true)
        )
        guard let view = controller.view else { return nil }
    
        let targetSize = view.intrinsicContentSize
        if targetSize.width <= 0 || targetSize.height <= 0 { return nil }
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = UIColor(backgroundColor)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
