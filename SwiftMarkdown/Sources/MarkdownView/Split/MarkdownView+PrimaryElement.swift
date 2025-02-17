//
//  MarkdownView+SplitPage.swift
//  SwiftMarkdown
//
//  Created by 孟超 on 2025/2/9.
//

import WebKit

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
/// 代码块可以断开. 只需要把代码块的样式设置为无边框即可.
/// 公式不可断开. 可以在绘制的时候进行恰当的放大.
/// 表格不可断开. 可以在绘制的时候进行恰当的放大.
@preconcurrency import PDFKit

@available(macOS 14.0, iOS 17.0, *)
extension MarkdownView.WebView {
    
    protocol ElementProvider {
        associatedtype Element
        var usingContentScale: Bool { get }
        var rect: CGRect { get }
        var subElements: [Element] { get }
        var subRects: [CGRect] { get }
    }
    
    public enum BasicElement: ElementProvider {
        typealias Element = Self
        var subElements: [Element] { [] }
        public enum HeadLevel {
            case h1,h2,h3,h4,h5,h6
        }
        
        var rect: CGRect {
            switch self {
                case .head(_, let rect, _): rect
                case .paragraph(let rect, _): rect
                case .text(let rect, _): rect
                case .divider(let rect): rect
                case .codeBlock(let rect, _): rect
            }
        }
        var subRects: [CGRect] {
            switch self {
                case .head(_, _, let rects): rects
                case .paragraph(_, let rects): rects
                case .text(_, let rects): rects
                case .divider: []
                case .codeBlock(_, let rects): rects
            }
        }
        var usingContentScale: Bool { false }
        case head(level: HeadLevel, rect: CGRect, textRects: [CGRect])
        case paragraph(rect: CGRect, textRects: [CGRect])
        case text(rect: CGRect, textRects: [CGRect])
        case divider(rect: CGRect)
        case codeBlock(rect: CGRect, textRects: [CGRect])
    }
    
    @available(macOS 14.0, iOS 17.0, *)
    /// The enumerate representing the element rect in the view.
    public enum PrimaryElement {
        case h1(rect: CGRect)
        case h2(rect: CGRect)
        case h3(rect: CGRect)
        case h4(rect: CGRect)
        case h5(rect: CGRect)
        case h6(rect: CGRect)
        case paragraph(rect: CGRect)
        case text(rect: CGRect)
        case divider(rect: CGRect)
        case orderList(rect: CGRect, subNodeRects: [CGRect])
        case disorderList(rect: CGRect, subNodeRects: [CGRect])
        case quoteBlock(rect: CGRect)
        case section(rect: CGRect)
        case divBlock(rect: CGRect)
        case unknown(rect: CGRect)
    }
    
    /// Get all the primary markdown-element frames about current document.
    @available(macOS 14.0, iOS 17.0, *)
    public func primaryFrames() async -> [PrimaryElement] {
        var rectArray = [PrimaryElement]()
        let result = try? await self.evaluateJavaScript("getPrimaryMarkdownElementFrames()")
        func getCGRectFromResultItem(_ result: [String : Any]) -> CGRect? {
            if let x = result["x"] as? CGFloat, let y = result["y"] as? CGFloat, let width = result["width"] as? CGFloat, let height = result["height"] as? CGFloat {
                return CGRect(x: x, y: y, width: width, height: height)
            }
            return nil
        }
        if let frames = result as? [[String: Any]] {
            for frame in frames {
                if let cgRect = getCGRectFromResultItem(frame), let nodeName = frame["node"] as? String {
                    let subNodes = (frame["subnodes"] as? [[String: Any]] ?? []).compactMap { getCGRectFromResultItem($0) }
                    let elementRect: PrimaryElement = switch nodeName.uppercased() {
                        case "H1": .h1(rect: cgRect)
                        case "H2": .h2(rect: cgRect)
                        case "H3": .h3(rect: cgRect)
                        case "H4": .h4(rect: cgRect)
                        case "H5": .h5(rect: cgRect)
                        case "H6": .h6(rect: cgRect)
                        case "SECTION": .section(rect: cgRect)
                        case "TEXT": .text(rect: cgRect)
                        case "HR": .divider(rect: cgRect)
                        case "P": .paragraph(rect: cgRect)
                        case "UL": .disorderList(rect: cgRect, subNodeRects: subNodes)
                        case "OL": .orderList(rect: cgRect, subNodeRects: subNodes)
                        case "BLOCKQUOTE": .quoteBlock(rect: cgRect)
                        case "DIV": .divBlock(rect: cgRect)
                        default: .unknown(rect: cgRect)
                    }
                    rectArray.append(elementRect)
                }
            }
        }
        return rectArray
    }
}
