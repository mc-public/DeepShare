//
//  WKWebView+PDF.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/5.
//
import WebKit
import UIKit

extension WKWebView {
    
    func pdfData(usingDivide: Bool = false) async -> Data? {
        if usingDivide {
            self.createPDFFile(printFormatter: self.viewPrintFormatter())
        } else {
            try? await self.pdf(configuration: .init())
        }
    }
    
    private func createPDFFile(printFormatter: UIViewPrintFormatter) -> Data {
        let originalBounds = self.bounds
        self.bounds = CGRect(x: originalBounds.origin.x,
                             y: bounds.origin.y,
                             width: self.bounds.size.width,
                             height: self.scrollView.contentSize.height)
        let pdfPageFrame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.scrollView.contentSize.height)
        let printPageRenderer = UIPrintPageRenderer()
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        printPageRenderer.setValue(NSValue(cgRect: UIScreen.main.bounds), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: pdfPageFrame), forKey: "printableRect")
        self.bounds = originalBounds
        return printPageRenderer.generatePDFData()
    }
}

extension UIPrintPageRenderer {
    
    func generatePDFData() -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        self.prepare(forDrawingPages: NSRange(location: 0, length: self.numberOfPages))
        let printRect = UIGraphicsGetPDFContextBounds()
        for pdfPage in 0..<self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: pdfPage, in: printRect)
        }
        UIGraphicsEndPDFContext()
        return Data(pdfData)
        
    }
}
