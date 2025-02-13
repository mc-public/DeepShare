//
//  QATemplateView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/13.
//

import UIKit
import SwiftUI

struct QATemplateView: View {
    let template: QATemplateModel
    let size: CGSize
    var body: some View {
        QATemplateDisplayView(template: template, size: size)
    }
}

fileprivate struct QATemplateDisplayView: UIViewRepresentable {
    let template: QATemplateModel
    let size: CGSize
    
    func makeUIView(context: Context) -> QATemplateContentView {
        QATemplateContentView()
    }
    
    func updateUIView(_ uiView: QATemplateContentView, context: Context) {
        uiView.preferredSize = size
        uiView.template = template
    }
    
    typealias UIViewType = QATemplateContentView
}

//MARK: - Template Auto-Growth View

fileprivate class UIPlainView: UIView {
    override class var layerClass: AnyClass {
        CAPlainLayer.self
    }
    
    class CAPlainLayer: CALayer {
        override class func defaultAction(forKey event: String) -> (any CAAction)? {
            nil
        }
    }
}

fileprivate class QATemplateContentView: UIPlainView {
    
    private var _template: QATemplateModel?
    
    var template: QATemplateModel? {
        get { _template }
        set {
            if _template == newValue { return }
            _template = newValue
            cleanRenderingCache()
            updateImages()
        }
    }
    
    private var _preferredSize = CGSize.zero
    
    var preferredSize: CGSize {
        get { _preferredSize }
        set {
            if _preferredSize == newValue {
                return
            }
            if !_preferredSize.width.isAlmostEqual(to: newValue.width) {
                cleanRenderingCache()
            }
            _preferredSize = newValue
            updateImages()
        }
    }
    
    private var renderingResult: QATemplateManager.TemplateRenderingResult?
    
    private var topImageView = UIPlainView()
    private var tileImageView = QATemplateTileView()
    private var bottomImageView = UIPlainView()
    private var textRectView = UIPlainView()
    
    override var intrinsicContentSize: CGSize {
        guard let template else {
            return CGSize(width: super.intrinsicContentSize.width, height: 0.0)
        }
        let size = QATemplateManager.current.pageRects(for: template, preferredSize: preferredSize)?.pageSize ?? .zero
        return size
    }
    
    private func cleanRenderingCache() {
        self.tileImageView.clean()
        self.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func updateImages() {
        guard let template else {
            return
        }
        if self.subviews.isEmpty {
            self.addSubview(self.topImageView)
            self.addSubview(self.tileImageView)
            self.addSubview(self.bottomImageView)
            self.addSubview(self.textRectView)
        }
        self.backgroundColor = template.textBackgroundColor
        guard let renderingResult = QATemplateManager.current.renderingResult(for: template, preferredSize: preferredSize) else {
            return
        }
        self.renderingResult = renderingResult
        
        self.topImageView.frame = renderingResult.topRect
        self.topImageView.layer.contents = renderingResult.topImage.cgImage
        
        /// Tile View
        let tilesRect = CGRect(
            origin: renderingResult.topRect.bottomLeading,
            size: CGSize(
                width: renderingResult.tileRects.first?.width ?? 0.0,
                height: renderingResult.bottomRect.minY - renderingResult.topRect.maxY
            )
        )
        self.tileImageView.applyTile(image: renderingResult.tileImage, frame: tilesRect)
        
        /// Bottom View
        bottomImageView.frame = renderingResult.bottomRect
        addSubview(bottomImageView)
        bottomImageView.layer.contents = renderingResult.bottomImage.cgImage
        
        textRectView.backgroundColor = .clear
        textRectView.layer.borderColor = UIColor.red.cgColor
        textRectView.layer.borderWidth = 3.0
        textRectView.frame = renderingResult.textRect
        self.bringSubviewToFront(textRectView)
        self.invalidateIntrinsicContentSize()
    }
    
}


fileprivate class QATemplateTileView: UIView {
    
    class ZeroFadeTiledLayer: CATiledLayer {
        override class func fadeDuration() -> CFTimeInterval {
            0.0
        }
    }
    
    override class var layerClass: AnyClass {
        ZeroFadeTiledLayer.self
    }
    
    weak var tiledLayer: ZeroFadeTiledLayer?
    var image: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tiledLayer = (self.layer as? ZeroFadeTiledLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTile(image: UIImage, frame: CGRect) {
        self.frame = frame
        self.image = image
        self.tiledLayer?.tileSize = image.size.pixelAligned
        self.tiledLayer?.levelsOfDetail = 0
        self.tiledLayer?.levelsOfDetailBias = 0
        self.clean()
    }
    
    override func draw(_ rect: CGRect) {
        guard let image else {
            return
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let bounds = context.boundingBoxOfClipPath
        UIGraphicsPushContext(context)
        image.draw(in: bounds)
        UIGraphicsPopContext()
    }
    
    func clean() {
        self.layer.contents = nil
        self.setNeedsDisplay(layer.bounds)
    }
}
