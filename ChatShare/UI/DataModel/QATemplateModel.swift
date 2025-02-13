//
//  QATemplateModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/13.
//

import UIKit
import UIColorHexSwift
import PDFKit

/// The data structure about the Question-Answer page template.
struct QATemplateModel: Identifiable, Sendable, Equatable {
    var id: String { title }
    /// The PDF file about the template.
    let pdfURL: URL
    /// The display title of the template.
    let title: String
    /// The size about the template image.
    let pageSize: CGSize
    /// The text-layoutable rectangle in the template page.
    let textRect: CGRect
    /// The background color about the text-layoutable rectangle.
    let textBackgroundColor: UIColor
    /// The height slice rectangle about the template image.
    let heightSliceRect: CGRect
    
    fileprivate init(pdfURL: URL, title: String, pageSize: CGSize, textRect: CGRect, textBackgroundColor: UIColor, heightSliceRect: CGRect) {
        self.pdfURL = pdfURL
        self.title = title
        self.pageSize = pageSize
        self.textRect = textRect
        self.textBackgroundColor = textBackgroundColor
        self.heightSliceRect = heightSliceRect
    }
    
    
    
}

/// The class used for managing QA page templates throughout the APP.
@Observable @MainActor
final class QATemplateManager {
    
    typealias ID = QATemplateModel.ID
    
    /// The shared template manager.
    static let current = QATemplateManager()
    /// All templates managed by the template manager.
    var allTemplates: [QATemplateModel]
    /// The default template.
    var defaultTemplate: QATemplateModel
    
    private var templatePagesCache: [ID: PDFPage] = [:]
    
    private typealias WidthToCacheMap = [CGFloat: TemplateRenderingCache]
    private var templateRenderingCache: [ID: WidthToCacheMap] = [:]
    
    private init() {
        let templates = Self.loadResources()
        self.allTemplates = templates
        self.defaultTemplate = templates[0]
    }
    
    func page(for template: QATemplateModel) -> PDFPage {
        if let page = templatePagesCache[template.id] {
            return page
        }
        guard let data = try? Data(contentsOf: template.pdfURL), let document = PDFDocument(data: data) else {
            fatalError("[\(Self.self)][\(#function)] Cannot load PDF file data at file URL `\(template.pdfURL.path(percentEncoded: false))`. Please check the data resource carefully.")
        }
        guard let page = document.page(at: 0) else {
            fatalError("[\(Self.self)][\(#function)] Cannot load PDF file page (index=zero) at file URL `\(template.pdfURL.path(percentEncoded: false))`. Please check the data resource carefully.")
        }
        templatePagesCache[template.id] = page
        return page
    }
    
    func renderingCache(for template: QATemplateModel, width: CGFloat, createCache: () -> TemplateRenderingCache) -> TemplateRenderingCache {
        guard let map = templateRenderingCache[template.id] else {
            let cache = createCache()
            templateRenderingCache[template.id] = [
                width: cache
            ]
            return cache
        }
        if let cache = map[width] {
            return cache
        } else {
            let cache = createCache()
            templateRenderingCache[template.id]?[width] = createCache()
            return cache
        }
    }
    
    
    private static func loadResources() -> [QATemplateModel] {
        guard let bundleURL = Bundle.main.url(forResource: "PageTemplate", withExtension: "bundle") else {
            fatalError("[\(Self.self)][\(#function)] Cannot load page template bundle resource.")
        }
        let jsonURL = bundleURL.appending(path: "templates.json")
        struct PageRect: Decodable {
            let x: CGFloat; let y: CGFloat
            let width: CGFloat; let height: CGFloat
            var rect: CGRect { .init(x: x, y: y, width: width, height: height) }
        }
        struct PageSize: Decodable {
            let width: CGFloat; let height: CGFloat
            var size: CGSize { .init(width: width, height: height) }
        }
        struct DataResource: Decodable {
            let name: String; let title: String
            let clip_start: CGFloat; let clip_stop: CGFloat
            let page_size: PageSize
            let text_box: PageRect
            let text_box_background: String
        }
        guard let jsonData = try? Data(contentsOf: jsonURL) else {
            fatalError("[\(Self.self)][\(#function)] Cannot load page template bundle JSON data.")
        }
        guard let dataList = try? JSONDecoder().decode([DataResource].self, from: jsonData) else {
            fatalError("[\(Self.self)][\(#function)] Cannot parse page template bundle JSON data.")
        }
        return dataList.map {
            let pdfURL = bundleURL.appending(path: $0.name)
            assert(FileManager.default.fileExists(at: pdfURL), "[\(Self.self)][\(#function)] Template PDF file cannot be loaded: `\(pdfURL.lastPathComponent)`. Please check resource files carefully.")
            return .init(
                pdfURL: bundleURL.appending(path: $0.name),
                title: $0.title,
                pageSize: $0.page_size.size,
                textRect: $0.text_box.rect,
                textBackgroundColor: UIColor($0.text_box_background),
                heightSliceRect: .init(x: 0, y: $0.clip_start, width: $0.page_size.width, height: $0.clip_stop - $0.clip_start)
            )
        }
    }
}
