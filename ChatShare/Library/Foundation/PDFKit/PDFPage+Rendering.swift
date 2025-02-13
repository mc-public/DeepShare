//
//  PDFPage+Rendering.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/13.
//

import PDFKit
import UIKit

extension PDFPage {
    
    /// Draw a rectangle from the page's MediaBox as a `UIImage`.
    ///
    /// - Parameter contentFrame: The content frame of the rendering rectangle in the MediaBox.
    /// - Parameter contentScale: The content scale about the renderer.
    /// - Parameter zoomScale: The zoom scale about the content frame. The result image will apply this scale.
    /// - Returns: Return a `UIImage` instance.
    func image(contentFrame: CGRect, contentScale: CGFloat, zoomScale: CGFloat) -> UIImage {
        let pageSize = self.bounds(for: .mediaBox).size
        let imageSize = contentFrame.size.scale(zoomScale)
        let renderingFormat = UIGraphicsImageRendererFormat()
        let contentFrameAtBottomLeading = CGRect(x: contentFrame.origin.x, y: pageSize.height - contentFrame.height - contentFrame.origin.y, width: contentFrame.width, height: contentFrame.height)
        renderingFormat.scale = contentScale
        renderingFormat.opaque = false
        renderingFormat.preferredRange = .automatic
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: renderingFormat)
        let uiImage = renderer.image { context in
            let ctx = context.cgContext
            let rect = CGRect(origin: .zero, size: imageSize)
//            ctx.interpolationQuality = .low
//            ctx.setRenderingIntent(.defaultIntent)
            ctx.fill(rect)
            ctx.translateBy(x: 0.0, y: imageSize.height)
            ctx.scaleBy(x: zoomScale, y: -zoomScale)
            ctx.translateBy(x: -contentFrameAtBottomLeading.origin.x, y: -contentFrameAtBottomLeading.origin.y)
            ctx.clip(to: contentFrameAtBottomLeading)
            self.draw(with: .mediaBox, to: context.cgContext)
        }
        return uiImage
    }
}
