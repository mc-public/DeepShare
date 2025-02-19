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
    @State var isDisable: Bool = true
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
                .disabled(isDisable)
                .frame(maxWidth: .infinity, maxHeight: 0.4 * windowSize.height)
        }
        .alert("Share Failured", isPresented: viewModel.binding(for: \.isShowingShareFailuredAlert), actions: {
            Button("OK") {}
        })
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
                .onRendered({
                    SVProgressHUD.dismiss()
                    self.isDisable = false
                })
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
            Button("Share", action: shareImage)
            .menuStyle(.button)
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.teal)
            .disabled(isDisable)
        }
    }
    
    func shareImage() {
        self.isDisable = true
        Task {
            SVProgressHUD.show()
            defer {
                SVProgressHUD.dismiss()
            }
            guard let url = await fetchLongImageResult() else {
                self.isDisable = false
                viewModel.isShowingShareFailuredAlert = true
                return
            }
            viewModel.imageResult = ShareFileURL(url: url)
            try? await Task.sleep(for: .microseconds(500))
            self.isDisable = false
        }
    }
    
    private func fetchLongImageResult() async -> URL? {
        let templatePreferredSize = QATemplateManager.current.preferredSize(for: viewModel.selectedTemplate, preferredWidth: scrollViewFrameSize.width, preferredTextHeight: textLayoutSize.height)
        guard let layoutResult = QATemplateManager.current.renderingResult(for: viewModel.selectedTemplate, preferredSize: templatePreferredSize) else {
            return nil
        }
        let titleRenderer = ImageRenderer(content: self.titleCell.frame(width: titleCellSize.width, height: titleCellSize.height))
        titleRenderer.scale = 3.0
        titleRenderer.proposedSize = .init(titleCellSize)
        guard let titleCellImage = titleRenderer.uiImage else {
            return nil
        }
        let textRectMinX = 0.5 * (windowSize.width - titleCellSize.width)
        let titleCellImageRect = CGRect.init(x: textRectMinX, y: layoutResult.textRect.minY, width: titleCellSize.width, height: titleCellSize.height)
        let totalBackgroundImage = await layoutResult.totalImage()
        guard let contentPDFData = await controller.container.pdfData(),
              let contentPDFDocument = PDFDocument(data: contentPDFData) else {
            return nil
        }
        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.preferredRange = .standard
        renderFormat.opaque = true
        renderFormat.scale = 3.0
        let renderer = UIGraphicsImageRenderer(size: totalBackgroundImage.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setShouldAntialias(false)
            totalBackgroundImage.draw(in: CGRect(origin: .zero, size: totalBackgroundImage.size))
            titleCellImage.draw(in: titleCellImageRect)
            for (index, rect) in contentPDFDocument.pageRects(width: textLayoutSize.width, minY: titleCellImageRect.maxY).enumerated() {
                guard let page = contentPDFDocument.page(at: index) else { fatalError() }
                page.image(width: textLayoutSize.width, contentScale: 3.0)
                    .draw(in: rect.offset(dx: textRectMinX))
            }
        }
        guard let pngData = image.pngData() else {
            return nil
        }
        let fileName = viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled"))
        guard let url = await URL.temporaryFileURL(data: pngData, fileName: fileName, conformTo: .png) else {
            return nil
        }
        return url
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
        Toggle("Author", isOn: viewModel.binding(for: \.usingWaterMark))
    }
    
    var usingTitleBorder: some View {
        Toggle("Title Background", isOn: viewModel.binding(for: \.usingTitleBorder))
    }
}


