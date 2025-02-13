//
//  PDFKit+UIImage.swift
//  SwiftMarkdown
//
//  Created by 孟超 on 2025/2/11.
//

import PDFKit
import UniformTypeIdentifiers

#if os(iOS)
import UIKit

extension PDFPage {
    var image: UIImage {
        get async {
            let pdfPageSize = self.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pdfPageSize)
                ctx.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                self.draw(with: .mediaBox, to: ctx.cgContext)
            }
            return image
        }
    }
}

func convertPDFToLongImage(pdfDocument: PDFDocument, fixedWidth: CGFloat, scale: CGFloat, outputURL: URL) throws {
    // 计算总高度和每页的位置
    var totalHeight: CGFloat = 0
    var pageRects = [CGRect]()
    
    for i in 0..<pdfDocument.pageCount {
        guard let page = pdfDocument.page(at: i) else { continue }
        let pageSize = page.bounds(for: .mediaBox).size
        let scaledHeight = (pageSize.height / pageSize.width) * fixedWidth * scale
        pageRects.append(CGRect(x: 0, y: totalHeight, width: fixedWidth * scale, height: scaledHeight))
        totalHeight += scaledHeight
    }
    let contextWidth = Int(fixedWidth * scale)
    let contextHeight = Int(totalHeight)
    let bytesPerRow = contextWidth * 4
    let byteCount = bytesPerRow * contextHeight
    
    // 创建临时文件并映射到内存
    let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("render.dat")
    FileManager.default.createFile(atPath: tempFileURL.path, contents: nil, attributes: nil)
    let fileHandle = try FileHandle(forWritingTo: tempFileURL)
    fileHandle.truncateFile(atOffset: UInt64(byteCount))
    try fileHandle.close()
    
    guard var data = try? Data(contentsOf: tempFileURL, options: .mappedIfSafe) else {
        throw NSError(domain: "MemoryMappingError", code: 0, userInfo: nil)
    }
    
    try data.withUnsafeMutableBytes { rawPtr in
        guard let ptr = rawPtr.baseAddress else {
            throw NSError(domain: "MemoryMappingError", code: 1, userInfo: nil)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: ptr, width: contextWidth, height: contextHeight,
                                     bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                     space: colorSpace, bitmapInfo: bitmapInfo) else {
            throw NSError(domain: "ContextCreationError", code: 0, userInfo: nil)
        }
        
        // 设置白色背景
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: contextWidth, height: contextHeight))
        
        // 逐页绘制
        for i in 0..<pdfDocument.pageCount {
            autoreleasepool {
                guard let page = pdfDocument.page(at: i) else { return }
                let rect = pageRects[i]
                
                context.saveGState()
                // 调整坐标系（Core Graphics原点在左下角）
                context.translateBy(x: 0, y: rect.origin.y)
                context.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: context)
                context.restoreGState()
            }
        }
        
        // 创建CGImage并保存为PNG
        guard let cgImage = context.makeImage() else {
            throw NSError(domain: "ImageCreationError", code: 0, userInfo: nil)
        }
        
        if let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, cgImage, nil)
            if !CGImageDestinationFinalize(destination) {
                throw NSError(domain: "PNGSaveError", code: 0, userInfo: nil)
            }
        } else {
            throw NSError(domain: "PNGSaveError", code: 1, userInfo: nil)
        }
    }
    
    try FileManager.default.removeItem(at: tempFileURL)
}

#endif
