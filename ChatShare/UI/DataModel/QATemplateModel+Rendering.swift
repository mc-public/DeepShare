//
//  QATemplateModel+Rendering.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/13.
//

import UIKit

extension QATemplateManager {
    
    /// Template image rendering information.
    struct TemplateRenderingResult {
        /// The total size about the rendering result.
        let size: CGSize
        /// The first `UIImage` instance about the template.
        let topImage: UIImage
        /// The first `UIImage` rectangle.
        let topRect: CGRect
        /// The tile image instance about the rendering result.
        let tileImage: UIImage
        /// The tile rectangles.
        let tileRects: [CGRect]
        /// The tile count.
        ///
        /// The value of this property `>=1`.
        var tileCount: Int {
            tileRects.count
        }
        /// The bottom image instance about the rendering result.
        let bottomImage: UIImage
        /// The bottom rectangle.
        let bottomRect: CGRect
        /// The text rendering rectangle in the image coordinator.
        let textRect: CGRect
        /// The background tone color under the text rendering rectangle.
        let textBackground: UIColor
    }
    /// A class used for caching the results of template rendering.
    struct TemplateRenderingCache {
        /// The first `UIImage` instance about the template.
        let topImage: UIImage
        /// The tile image instance about the rendering result.
        let tileImage: UIImage
        /// The bottom image instance about the rendering result.
        let bottomImage: UIImage
    }
    
    /// Get the rendering information of a certain template in the page coordinate system.
    func pageRects(for template: QATemplateModel) -> (pageSize: CGSize, topRect: CGRect, tileRect: CGRect, bottomRect: CGRect, layoutRect: CGRect) {
        let page = self.page(for: template)
        let pageSize = page.bounds(for: .mediaBox).size
        let pdfScale = pageSize.height / template.pageSize.height
        /// The page rect in UIKit page coordinate.
        let pageRect = CGRect(origin: .zero, size: pageSize)
        /// The layout rect in UIKit page coordinate.
        let layoutRect = template.textRect.scale(pdfScale)
        /// The height-append rect in UIKit page coordinate.
        let tileRect = template.heightSliceRect.scale(pdfScale)
        /// The top rect about the image.
        let firstPartRect = CGRect(origin: .zero, size: CGSize(width: pageRect.width, height: tileRect.minY))
        /// The final rect about the image.
        let finalPartRect = CGRect(origin: tileRect.bottomLeading, size: CGSize(width: pageRect.width, height: pageRect.height - tileRect.maxY))
        return (pageSize: pageRect.size, topRect: firstPartRect, tileRect: tileRect, bottomRect: finalPartRect, layoutRect: layoutRect)
    }
    
    func preferredSize(for template: QATemplateModel, preferredWidth: CGFloat, preferredTextHeight: CGFloat) -> CGSize {
        
        if preferredWidth.isAlmostZero() || preferredWidth.isAlmostZero() { return .zero }
        let pageInfo = self.pageRects(for: template)
        let pageScale = preferredWidth / pageInfo.pageSize.width
        let marginHeight = pageInfo.pageSize.scale(pageScale).height - pageInfo.layoutRect.scale(pageScale).height
        let totalHeight = max(preferredTextHeight, pageInfo.layoutRect.scale(pageScale).height) + marginHeight
        return CGSize(width: preferredWidth, height: totalHeight)
    }
    
    func pageRects(for template: QATemplateModel, preferredSize: CGSize) -> (scale: CGFloat, pageSize: CGSize, topRect: CGRect, tileCount: Int, tileHeight: CGFloat, tileRects: [CGRect], bottomRect: CGRect, layoutRect: CGRect)? {
        if preferredSize.width.isAlmostZero() || preferredSize.height.isAlmostZero() { return nil }
        let pageInfo = self.pageRects(for: template)
        let pageScale = preferredSize.width / pageInfo.pageSize.width
        let rescaledPreferredSize = preferredSize.rescale(pageScale)
        if rescaledPreferredSize.height <= pageInfo.pageSize.height {
            return (
                scale: pageScale,
                pageSize: pageInfo.pageSize.scale(pageScale),
                topRect: pageInfo.topRect.scale(pageScale),
                tileCount: 1,
                tileHeight: pageInfo.tileRect.scale(pageScale).height,
                tileRects: [pageInfo.tileRect.scale(pageScale)],
                bottomRect: pageInfo.bottomRect.scale(pageScale),
                layoutRect: pageInfo.layoutRect.scale(pageScale)
            )
        }
        // Tile Count
        let tileMinHeight = rescaledPreferredSize.height - pageInfo.topRect.height - pageInfo.bottomRect.height

        let tileCount = Int(ceil(tileMinHeight / pageInfo.tileRect.height))
        let appendedTileCount = tileCount - 1
        let tileRects = (0..<tileCount).map {
            CGRect(origin: CGPoint(x: 0, y: pageInfo.tileRect.origin.y + CGFloat($0) * pageInfo.tileRect.height), size: pageInfo.tileRect.size)
        }
        let heightDelta = CGFloat(appendedTileCount) * pageInfo.tileRect.height
        // Appended Frames
        let pageSize = pageInfo.pageSize.offset(dw: 0, dh: heightDelta)
        let bottomRect = CGRect(
            origin: pageInfo.bottomRect.origin.offset(dy: heightDelta),
            size: pageInfo.bottomRect.size
        )
        let layoutRect = pageInfo.layoutRect.offset(dh: heightDelta)
        return (
            scale: pageScale,
            pageSize: pageSize.scale(pageScale),
            topRect: pageInfo.topRect.scale(pageScale),
            tileCount: tileCount,
            tileHeight: tileRects.first?.scale(pageScale).height ?? 0,
            tileRects: tileRects.map { $0.scale(pageScale) },
            bottomRect: bottomRect.scale(pageScale),
            layoutRect: layoutRect.scale(pageScale)
        )
    }
    
    func renderingResult(for template: QATemplateModel, preferredSize: CGSize) -> TemplateRenderingResult? {
        guard let pageInfo = self.pageRects(for: template, preferredSize: preferredSize) else {
            return nil
        }
        let originInfo = self.pageRects(for: template)
        let page = self.page(for: template)
        let cache = self.renderingCache(for: template, width: preferredSize.width) {
            let topImage = page.image(contentFrame: originInfo.topRect, contentScale: 2.0, zoomScale: pageInfo.scale)
            let tileImage = page.image(contentFrame: originInfo.tileRect, contentScale: 2.0, zoomScale: pageInfo.scale)
            let bottomImage = page.image(contentFrame: originInfo.bottomRect, contentScale: 2.0, zoomScale: pageInfo.scale)
            return .init(topImage: topImage, tileImage: tileImage, bottomImage: bottomImage)
        }
        return TemplateRenderingResult(
            size: pageInfo.pageSize,
            topImage: cache.topImage,
            topRect: pageInfo.topRect,
            tileImage: cache.tileImage,
            tileRects: pageInfo.tileRects,
            bottomImage: cache.bottomImage,
            bottomRect: pageInfo.bottomRect,
            textRect: pageInfo.layoutRect,
            textBackground: template.textBackgroundColor
        )
    }
}
