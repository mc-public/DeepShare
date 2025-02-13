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
            if _preferredSize == newValue { return }
            if !_preferredSize.width.isAlmostEqual(to: newValue.width) {
                cleanRenderingCache()
            }
            _preferredSize = newValue
            updateImages()
        }
    }
    
    private var renderingResult: QATemplateManager.TemplateRenderingResult?
    
    private var topImageView = UIPlainView()
    private var tileImageViewReusePool = Set<UIPlainView>()
    private var bottomImageView = UIPlainView()
    
    override var intrinsicContentSize: CGSize {
        guard let template else {
            return CGSize(width: super.intrinsicContentSize.width, height: 0.0)
        }
        let size = QATemplateManager.current.pageRects(for: template, preferredSize: preferredSize)?.pageSize ?? .zero
        return size
    }
    
    private func cleanRenderingCache() {
        self.subviews.forEach { $0.removeFromSuperview() }
        self.tileImageViewReusePool = .init()
    }
    
    private func updateImages() {
        
        guard let template else {
            return
        }
        self.backgroundColor = template.textBackgroundColor
        guard let renderingResult = QATemplateManager.current.renderingResult(for: template, preferredSize: preferredSize) else {
            return
        }
        self.renderingResult = renderingResult
        /// Top View
        let topImageView =  UIImageView(image: renderingResult.topImage)
        self.addSubview(topImageView)
        topImageView.frame = renderingResult.topRect
        /// Tile Views
        for tileIndex in 0..<renderingResult.tileCount {
            let tileImageView = UIPlainView()
            tileImageView.layer.allowsEdgeAntialiasing = false
            tileImageView.layer.contents = renderingResult.tileImage.cgImage
            //self.addSubview(tileImageView)
            tileImageView.frame = renderingResult.tileRects[tileIndex].pixelAligned
            tileImageView.layer.masksToBounds = true
        }
        /// Bottom View
        let bottomImageView = UIView()
        bottomImageView.layer.contents = renderingResult.bottomImage.cgImage
        self.addSubview(bottomImageView)
        bottomImageView.frame = renderingResult.bottomRect
//        let layoutAreaView = UIView()
//        layoutAreaView.backgroundColor = .clear
//        layoutAreaView.layer.borderColor = UIColor.red.cgColor
//        layoutAreaView.layer.borderWidth = 3.0
//        self.addSubview(layoutAreaView)
//        layoutAreaView.frame = renderingResult.textRect
//        print(renderingResult.textRect)
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
        CATiledLayer.self
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
        self.tiledLayer?.tileSize = image.size
        self.layer.contents = nil
        self.setNeedsDisplay(layer.bounds)
    }
    
    override func draw(_ rect: CGRect) {
        guard let image else { return }
        image.draw(in: rect)
    }
}
