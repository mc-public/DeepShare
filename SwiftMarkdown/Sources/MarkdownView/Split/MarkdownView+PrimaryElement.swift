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

@preconcurrency import PDFKit

extension MarkdownView.WebView {
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
