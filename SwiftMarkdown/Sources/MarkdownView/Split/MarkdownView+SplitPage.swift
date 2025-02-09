//
//  MarkdownView+SplitPage.swift
//  SwiftMarkdown
//
//  Created by 孟超 on 2025/2/9.
//

import WebKit
import PDFKit

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

//MARK: - Single Page Image
@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView.WebView {
    
    /// Generate a full-page image of the Markdown document.
    ///
    /// - Parameter width: The page width of the image. The height of the image will be automatically calculated based on the content of the Markdown document.
    @available(macOS 14.0, iOS 17.0, *)
    public func contentImage(width: CGFloat?) async -> PlatformImage? {
        let config = WKPDFConfiguration()
        if #available(iOS 17.0, macOS 14.0, *) {
            config.allowTransparentBackground = false
        }
        guard let pdfData = try? await self.pdf(configuration: config) else {
            return nil
        }
        let width = width ?? self.bounds.width
        return await withCheckedContinuation { (cont: CheckedContinuation<PlatformImage?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pdfDocument = PDFDocument(data: pdfData) else {
                    cont.resume(returning: nil)
                    return
                }
                assert(pdfDocument.pageCount == 1)
                guard let page = pdfDocument.page(at: 0) else {
                    cont.resume(returning: nil)
                    return
                }
                let pageSize = page.bounds(for: .mediaBox).size
                let targetHeight = (width / pageSize.width) * pageSize.height
                cont.resume(returning: page.thumbnail(of: CGSize(width: width, height: targetHeight), for: .mediaBox))
            }
        }
    }
    
    /// Generate a full-page image of the Markdown document.
    ///
    /// - Parameter width: The page width of the image. The height of the image will be automatically calculated based on the content of the Markdown document.
    @available(macOS 14.0, iOS 17.0, *)
    public func contentPDFData(width: CGFloat?) async -> Data? {
        let config = WKPDFConfiguration()
        if #available(iOS 17.0, macOS 14.0, *) {
            config.allowTransparentBackground = false
        }
        guard let pdfData = try? await self.pdf(configuration: config) else {
            return nil
        }
        let width = width ?? self.bounds.width
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return nil
        }
        assert(pdfDocument.pageCount == 1)
        guard let page = pdfDocument.page(at: 0) else {
            return nil
        }
        return pdfData
    }
}

//MARK: - Page Split Images
@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView.WebView {
    
    /// Possible page break points when dividing a Markdown page.
    ///
    /// The pagination algorithm will divide the pages using the set of options specified at the time of partitioning.
    @available(macOS 14.0, iOS 17.0, *)
    public struct PageSplitLocation: OptionSet, Sendable {
        /// The raw value about current location.
        public var rawValue: Int
        /// Forcefully split the page at the `---` in the Markdown document.
        public static let divider = Self(rawValue: 1 << 0)
        /// Allow split the page before the title in the Markdown document.
        public static let title = Self(rawValue: 1 << 1)
        /// Allow breaking lists when splitting.
        public static let list = Self(rawValue: 1 << 2)
        /// Allow breaking paragraph.
        public static let paragraph = Self(rawValue: 1 << 3)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    /// Pagination algorithms available for dividing Markdown page.
    @available(macOS 14.0, iOS 17.0, *)
    public enum PageSplitAlgorithm {
        /// Use the greedy algorithm to partition the page from top to bottom.
        case greedy
        /// Use the Knuth-Plass page-breaking (using in LaTeX) algorithm to divide pages.
        case latex
    }
    
    /// Using greedy algorithm to split the Markdown elements.
    private func greedySplit() async {
        struct VirtualPage {
            var rect: CGRect
            var elements: [PrimaryElement]
        }
        
    }
    
    
    @available(iOS 17.0, *)
    public func splitToImages(width: CGFloat? = nil) async -> [PlatformImage] {
        let elementRects = await self.primaryFrames()
        if elementRects.isEmpty { return [] }
        /// Split the page according to the primary elements in the markdown file.
        
        func addBlackSubview(for rect: CGRect) {
            let view = PlatformView()
#if os(macOS)
            view.layer?.borderWidth = 2.0
#elseif os(iOS)
            view.layer.borderWidth = 2.0
#endif
            self.addSubview(view)
            view.frame = rect
        }
        for elementRect in elementRects {
            switch elementRect {
                case .h1(let rect):
                    addBlackSubview(for: rect)
                case .h2(let rect):
                    addBlackSubview(for: rect)
                case .h3(let rect):
                    addBlackSubview(for: rect)
                case .h4(let rect):
                    addBlackSubview(for: rect)
                case .h5(let rect):
                    addBlackSubview(for: rect)
                case .h6(let rect):
                    addBlackSubview(for: rect)
                case .text(let rect):
                    addBlackSubview(for: rect)
                case .paragraph(let rect):
                    addBlackSubview(for: rect)
                case .divider(let rect):
                    addBlackSubview(for: rect)
                case .orderList(let rect, let subNodeRects):
                    addBlackSubview(for: rect)
                    for subNodeRect in subNodeRects {
                        addBlackSubview(for: subNodeRect)
                    }
                case .disorderList(let rect, let subNodeRects):
                    addBlackSubview(for: rect)
                    for subNodeRect in subNodeRects {
                        addBlackSubview(for: subNodeRect)
                    }
                case .quoteBlock(let rect):
                    addBlackSubview(for: rect)
                case .section(let rect):
                    addBlackSubview(for: rect)
                case .divBlock(let rect):
                    addBlackSubview(for: rect)
                case .unknown(let rect):
                    addBlackSubview(for: rect)
            }
        }
        return []
    }

}
