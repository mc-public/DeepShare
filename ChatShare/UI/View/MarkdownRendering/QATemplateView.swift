//
//  QATemplateView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/13.
//

import UIKit
import SwiftUI
import SnapKit

//MARK: - QATemplateRotationView

struct QATemplateRotationView<Content>: View where Content: View {
    let template: QATemplateModel
    let pageRotation: QAPageRotation
    let horizontalPadding: CGFloat
    let content: () -> Content
    
    var body: some View {
        GeometryReader { proxy in
            let preferredSize = pageRotation.size(width: proxy.size.width)
            let containerLayout = QATemplateManager.current.pageRects(for: template, preferredSize: preferredSize)
            let totalSize = containerLayout?.pageSize ?? .zero
            let layoutRect = containerLayout?.layoutRect ?? .zero
            Frame(totalSize, alignment: .top) {
                VStack(alignment: .center, spacing: 0.0) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: containerLayout?.layoutRect.minY ?? 0.0)
                    Frame(width: max(0.0, layoutRect.width - horizontalPadding), height: layoutRect.height, alignment: .top) {
                        ScrollView(.vertical) {
                            content()
                        }
                    }
                }
            }.background(alignment: .topLeading) {
                QATemplateDisplayView(template: template, size: totalSize)
            }
        }
    }
    
    var textContent: some View {
        VStackLayout(alignment: .center, spacing: 0.0) {
            content()
        }
    }
}

//MARK: - QATemplateScrollView

struct QATemplateScrollView<Content>: View where Content: View {

    let template: QATemplateModel
    let horizontalPadding: CGFloat
    @Binding var textLayoutSize: CGSize
    let content: () -> Content
   
    var body: some View {
        GeometryReader { proxy in
            let templatePreferredSize = QATemplateManager.current.preferredSize(for: template, preferredWidth: proxy.size.width, preferredTextHeight: textLayoutSize.height)
            QAScrollTemplateContainer(template: template, horizontalPadding: horizontalPadding, preferredSize: templatePreferredSize) {
                textContent
            }
        }
    }
    
    var textContent: some View {
        VStackLayout(alignment: .center, spacing: 0.0) {
            content()
                .onGeometryChange(body: {
                    textLayoutSize = $0
                })
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

fileprivate struct QAScrollTemplateContainer<Content>: View where Content: View {
    let template: QATemplateModel
    let horizontalPadding: CGFloat
    let preferredSize: CGSize
    let content: () -> Content
    var body: some View {
        let containerLayout = QATemplateManager.current.pageRects(for: template, preferredSize: preferredSize)
        let totalSize = containerLayout?.pageSize ?? .zero
        let layoutRect = containerLayout?.layoutRect ?? .zero
        ScrollView(.vertical) {
            Frame(totalSize, alignment: .top) {
                VStack(alignment: .center, spacing: 0.0) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: containerLayout?.layoutRect.minY ?? 0.0)
                    Frame(width: max(0.0, layoutRect.width - horizontalPadding), height: layoutRect.height, alignment: .top) {
                        content()
                    }
//                        .border(.yellow, width: 5.0)
                }
            }
//                .border(.black, width: 10)
            .background(alignment: .topLeading) {
                QATemplateDisplayView(template: template, size: totalSize)
            }
        }
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
    
    private var renderingResult: QATemplateManager.TemplateRenderingResult? {
        didSet {
            self.backgroundColor = renderingResult?.textBackground
        }
    }
    
    private var topImageView = UIPlainView()
    private var tileImageView = UIImageView()
    private var bottomImageView = UIPlainView()
    private var textRectView = UIPlainView()
    
    private func cleanRenderingCache() {
//        self.tileImageView.clean()
        self.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func updateImages() {
        guard let template else { return }
        if self.subviews.isEmpty {
            self.addSubview(self.topImageView)
            self.addSubview(self.tileImageView)
            self.addSubview(self.bottomImageView)
            self.addSubview(self.textRectView)
            self.topImageView.layer.allowsEdgeAntialiasing = false
            self.tileImageView.layer.allowsEdgeAntialiasing = false
            self.bottomImageView.layer.allowsEdgeAntialiasing = false
        }
        guard let renderingResult = QATemplateManager.current.renderingResult(for: template, preferredSize: preferredSize) else {
            return
        }
        let topImageViewHeight = renderingResult.topRect.height
        let tileImageViewHeight = CGFloat(renderingResult.tileRects.count) * (renderingResult.tileImage.size.height)
        let bottomImageViewHeight = renderingResult.bottomRect.height
        print(topImageViewHeight + tileImageViewHeight + bottomImageViewHeight, renderingResult.size.height)
        self.renderingResult = renderingResult
        self.topImageView.snp.remakeConstraints { make in
            make.top.equalTo(self)
            make.width.equalTo(renderingResult.topRect.width)
            make.height.equalTo(topImageViewHeight)
        }
        self.topImageView.layer.contents = renderingResult.topImage.cgImage
        /// Tile View
        guard let topTileRect = renderingResult.tileRects.first else {
            fatalError("[\(Self.self)][\(#function)] Cannot unwrap the first rectangle about the tiles.")
        }
        self.tileImageView.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(topImageViewHeight)
            make.width.equalTo(topTileRect.width)
            make.height.equalTo(tileImageViewHeight)
        }
        self.tileImageView.image = renderingResult.tileImage.resizableImage(withCapInsets: .zero, resizingMode: .tile)
        /// Bottom View
        self.bottomImageView.snp.remakeConstraints { make in
            make.top.equalTo(self.tileImageView.snp.bottom)
            make.height.equalTo(bottomImageViewHeight)
            make.width.equalTo(renderingResult.bottomRect.width)

        }
        self.bottomImageView.layer.contents = renderingResult.bottomImage.cgImage
        
//        textRectView.backgroundColor = .clear
//        textRectView.layer.borderColor = UIColor.red.cgColor
//        textRectView.layer.borderWidth = 3.0
//        textRectView.frame = renderingResult.textRect
//        self.bringSubviewToFront(textRectView)
        self.snp.remakeConstraints { make in
            make.height.lessThanOrEqualTo(renderingResult.size.height)
        }
    }
}
