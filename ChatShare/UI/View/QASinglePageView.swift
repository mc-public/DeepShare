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

struct QASinglePageView: QANavigationLeaf {
    
    @State var controller = MarkdownState()
    @State var windowSize: CGSize = .zero
    @State var textLayoutSize = CGSize.zero
    @State var titleCellSize = CGSize.zero
    @State var scrollViewFrameSize = CGSize.zero
    @State var isDisable: Bool = true
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(\.dismiss) var dismiss
    
    var navigationTitleColor: Color { .dynamicBlack }
    
    var content: some View {
        QATemplateScrollView(
            template: viewModel.selectedTemplate,
            horizontalPadding: viewModel.horizontalPagePadding,
            textLayoutSize: $textLayoutSize,
            content: { markdownContent }
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
        .onDisappear(perform: SVProgressHUD.dismiss)
        .environment(\.dynamicTypeSize, .medium)
        .onChange(of: viewModel.selectedTemplate, initial: true) { _, newValue in
            viewModel.updateSuggestedPagePadding(pageWidth: scrollViewFrameSize.width)
            controller.backgroundColor = Color(newValue.textBackgroundColor).opacity(0)
        }
        .onChange(of: controller.theme, initial: true) { _, _ in
            controller.backgroundColor = Color(viewModel.selectedTemplate.textBackgroundColor).opacity(0)
        }
    }
    
    
    @ViewBuilder
    var markdownContent: QARenderingContentView {
        QARenderingContentView(viewModel: self.viewModel, controller: $controller, titleCellSize: $titleCellSize, isDisabled: $isDisable)
    }
    
}

extension QASinglePageView {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
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
        let titleRenderer = ImageRenderer(
            content: self.markdownContent
                .titleCell
                .frame(width: titleCellSize.width, height: titleCellSize.height)
                .environment(\.colorScheme, .light)
        )
        titleRenderer.scale = 3.0
        titleRenderer.proposedSize = .init(titleCellSize)
        guard let titleCellImage = titleRenderer.uiImage else {
            return nil
        }
        let textRectMinX = layoutResult.textRect.minX + viewModel.horizontalPagePadding
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
        .onChange(of: viewModel.verticalPagePadding, initial: true, { _, newValue in
            markdownController.bottomPadding = newValue
        })
        .onChange(of: viewModel.horizontalPagePadding, initial: true, { _, newValue in
            markdownController.horizontalPadding = newValue
        })
    }
    
    var content: some View {
        List {
            Section("Style") {
                QAPageSettingLabel.usingWaterMarkLabel(viewModel: viewModel)
                QAPageSettingLabel.usingTitleBorder(viewModel: viewModel)
                QAPageSettingLabel.templateLabel(viewModel: viewModel)
                themeLabel
                fontSizeLabel
                QAPageSettingLabel.pageHorizontalPaddingLabel(viewModel: viewModel, markdownState: markdownController)
                QAPageSettingLabel.pageVerticalPaddingLabel(viewModel: viewModel)
            }
        }
        .scrollContentBackground(.hidden)
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
    
    var themeLabel: some View {
        Picker("Markdown Theme", selection: markdownController.binding(for: \.theme)) {
            ForEach(MarkdownView.Theme.allCases) { theme in
                Text(theme.name).tag(theme)
            }
        }
    }
}


