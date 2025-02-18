//
//  QARenderingView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import MarkdownView
import SVProgressHUD
import Localization
import PDFKit

//MARK: - QA Result Display (Rendering) View

struct QASinglePageRenderingView: QANavigationLeaf {
    
    @State var controller = MarkdownState()
    @State var windowSize: CGSize = .zero
    @State var textLayoutSize = CGSize.zero
    @State var titleCellSize = CGSize.zero
    @State var scrollViewFrameSize = CGSize.zero
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    
    var navigationTitleColor: Color { .dynamicBlack }
    
    var content: some View {
        QATemplateScrollView(
            template: viewModel.selectedTemplate,
            horizontalPadding: viewModel.horizontalPagePadding,
            textLayoutSize: $textLayoutSize,
            content: verticalStack
        )
        .onGeometryChange(body: { scrollViewFrameSize = $0 })
        .scrollBackgroundColor(controller.backgroundColor)
        .scrollEdgeColor(.top, .bottom, color: controller.backgroundColor)
        .environment(\.colorScheme, .light)
        .toolbar(content: toolbarContent)
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0.0) {
            QARenderingSettingsView(markdownController: $controller)
                .frame(maxWidth: .infinity, maxHeight: 0.4 * windowSize.height)
        }
        .onGeometryChange(body: { windowSize = $0 })
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .fileShareSheet(item: viewModel.binding(for: \.imageResult))
        .fileShareSheet(item: viewModel.binding(for: \.pdfResult))
        .onAppear(perform: onAppear)
        .onDisappear(perform: SVProgressHUD.dismiss)
        .environment(\.dynamicTypeSize, .medium)
        .onChange(of: viewModel.selectedTemplate, initial: true) { _, newValue in
            controller.backgroundColor = Color(newValue.textBackgroundColor).opacity(0)
        }
    }
    
    @ViewBuilder
    var titleCell: some View {
        VStackLayout(alignment: .center) {
            Text(viewModel.questionContent)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .font(.preferredFont(relativeMetric: controller.fontSize, style: .title1))
                .fontWidth(.condensed)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            if viewModel.usingWaterMark {
                ChatModelInfoCell(chatModel: viewModel.selectedChatAI)
                    .font(.preferredFont(relativeMetric: controller.fontSize, style: .footnote))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.top, length: 10.0)
        .padding(.bottom, viewModel.usingWaterMark ? 5.0 : 10.0)
        .withCondition(body: { view in
            if viewModel.usingTitleBorder {
                view.withCornerBackground(radius: 10.0, style: Material.ultraThinMaterial)
            } else { view }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, controller.horizontalPadding)
        .padding(.vertical)
        .background(controller.backgroundColor, ignoresSafeAreaEdges: .all)
    }
    
    @ViewBuilder
    func verticalStack() -> some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            if !viewModel.questionContent.isEmpty {
                titleCell
                    .onGeometryChange(body: { titleCellSize = $0 })
            }
            Markdown(state: $controller)
                .onRendered(SVProgressHUD.dismiss)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .hidden(controller.isRenderingContent)
    }
    
    func onAppear() {
        controller.text = viewModel.answerContent
        controller.backgroundColor = .clear
        SVProgressHUD.show()
    }
    
}

extension QASinglePageRenderingView {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Share") {
                Button("Share as PDF") {
                    Task {
                        viewModel.pdfResult = ShareFileURL(url: await fetchPDFResult())
                    }
                }
                Button("Share as Long Image", systemImage: "square.and.arrow.up") {
                    Task {
                        viewModel.imageResult = ShareFileURL(url: await fetchLongImageResult())
                    }
                }
                Button("按段落划分后分享", systemImage: "square.and.arrow.up") {
                    Task {
                        await controller.container.splitToImages()
                    }
                }
            }
            .menuStyle(.button)
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.teal)
        }
    }
    
    func fetchLongImageResult() async -> URL? {
        let templatePreferredSize = QATemplateManager.current.preferredSize(for: viewModel.selectedTemplate, preferredWidth: scrollViewFrameSize.width, preferredTextHeight: textLayoutSize.height)
        guard let layoutResult = QATemplateManager.current.renderingResult(for: viewModel.selectedTemplate, preferredSize: templatePreferredSize) else {
            fatalError()
        }
        guard let titleCellImage = ImageRenderer(content: self.titleCell.frame(width: titleCellSize.width, height: titleCellSize.height)).uiImage else {
            fatalError()
        }
        let titleCellImageRect = CGRect.init(x: 0.5 * (windowSize.width - titleCellSize.width), y: layoutResult.textRect.minY, width: titleCellSize.width, height: titleCellSize.height)
        let totalBackgroundImage = await layoutResult.totalImage()
        guard let contentPDFData = await controller.container.pdfData(), let document = PDFDocument(data: contentPDFData) else {
            return nil
        }
        
        //let markdownContentImage
        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.opaque = true
        renderFormat.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: totalBackgroundImage.size)
        renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setShouldAntialias(false)
            totalBackgroundImage.draw(in: CGRect(origin: .zero, size: totalBackgroundImage.size))
            titleCellImage.draw(in: titleCellImageRect)
        }
        
        fatalError()
//        guard let pngData = image.pngData() else {
//            return nil
//        }
//        
//        let fileName = viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled"))
//        guard let url = await URL.temporaryFileURL(data: pngData, fileName: fileName, conformTo: .png) else {
//            return nil
//        }
//        return url
    }
    
    func fetchSplitedImage() async -> UIImage? {
        
        Task {
            _ = await controller.container.splitToImages()
        }
        return nil
    }
    
    func fetchPDFResult() async -> URL? {
        guard let data = await controller.container.contentPDFData(width: nil) else { return nil }
        let fileName = viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled"))
        guard let pdfURL = await URL.temporaryFileURL(data: data, fileName: fileName, conformTo: .pdf) else {
            return nil
        }
        return pdfURL
    }
}

//MARK: - Chat Rendering Setting View
fileprivate struct QARenderingSettingsView: View {
    @Binding var markdownController: MarkdownState
    @Environment(QAViewModel.self) var viewModel
    var body: some View {
        VStack(alignment: .center, spacing: 0.0) {
            Divider()
            content
                .dynamicTypeSize(.small)
        }
        .background(Material.ultraThick, ignoresSafeAreaEdges: .all)
    }
    
    var content: some View {
        List {
            Section("Style") {
                usingWaterMarkLabel
                usingTitleBorder
                templateLabel
                themeLabel
                fontSizeLabel
                pageHorizontalPaddingLabel
            }
            
        }
        .scrollContentBackground(.hidden)
    }
    
    var templateLabel: some View {
        Picker("Template", selection: viewModel.binding(for: \.selectedTemplate)) {
            ForEach(QATemplateManager.current.allTemplates) { template in
                Text(template.title).tag(template)
            }
        }
    }
    
    var fontSizeLabel: some View {
        VStack {
            HStack {
                Text("Text Size")
                Spacer()
                Text(String(format: "%.1f", markdownController.fontSize) + " pt")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $markdownController.fontSize, in: 3.0...25.0, step: 0.1, label: {  }, minimumValueLabel: { Image(systemName: "textformat.size.smaller") }, maximumValueLabel: { Image(systemName: "textformat.size.larger") })
        }
    }
    
    var backgroundColorLabel: some View {
        ColorPicker("Background Color", selection: markdownController.binding(for: \.backgroundColor), supportsOpacity: true)
            .environment(\.dynamicTypeSize, .xSmall)
    }
    
    var themeLabel: some View {
        Picker("Markdown Theme", selection: markdownController.binding(for: \.theme)) {
            ForEach(MarkdownView.Theme.allCases) { theme in
                Text(theme.name).tag(theme)
            }
        }
    }
    
    var pageHorizontalPaddingLabel: some View {
        VStack {
            HStack {
                Text("Horizontal Page Margins")
                Spacer()
                Text(String(format: "%.1f", markdownController.horizontalPadding) + " pt")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $markdownController.horizontalPadding, in: 10.0...50.0, step: 1.0, label: {  }, minimumValueLabel: { Image(systemName: "number").imageScale(.small) }, maximumValueLabel: { Image(systemName: "number").imageScale(.medium) })
        }
    }
    
    var usingWaterMarkLabel: some View {
        Toggle("Display Author", isOn: viewModel.binding(for: \.usingWaterMark))
    }
    
    var usingTitleBorder: some View {
        Toggle("Title Background", isOn: viewModel.binding(for: \.usingTitleBorder))
    }
}


//MARK: - Chat Robot Display Cell
fileprivate struct ChatModelInfoCell: View {
    let chatModel: QAChatAIModel
    var body: some View {
        HStackLayout(alignment: .firstTextBaseline) {
            Image(systemName: "checkmark.icloud.fill")
                .foregroundStyle(.green)
            Text(chatModel.rawValue)
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
        }
    }
}
