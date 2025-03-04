//
//  QASplitedPagesView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI
import MarkdownView
import SVProgressHUD
import Localization
import PDFPreviewer
import PDFKit

struct QAImageConvertSplitedPagesView: View {
    
    struct RenderingResult: Identifiable {
        let id = UUID()
        let data: Data
        let url: URL
    }
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var markdownState = MarkdownState()
    /// Disabled critical buttons when rendering contents.
    @State var isDisabled = true
    /// View size states.
    @State var titleCellSize = CGSize.zero
    @State var windowSize = CGSize.zero
    @State var fontSize: DownTeX.FontSize = .pt14
    /// Rendering results.
    @State var renderingResult: RenderingResult?
    
    var body: some View {
        NavigationStack {
            content
        }
        .onGeometryChange(body: { windowSize = $0 })
        .onDisappear(perform: {
            viewModel.cleanRenderingOptions()
            markdownState.cleanMemory()
        })
    }
    
    @ViewBuilder
    var content: some View {
        let preferredSize = viewModel.pageRotation.size(width: windowSize.width)
        let containerLayout = QATemplateManager.current.pageRects(for: viewModel.selectedTemplate, preferredSize: preferredSize)
        let previewContentSize = containerLayout?.pageSize ?? .zero
        let topCellHeight = 0.7 * windowSize.height
        let contentView = VStack(spacing: 0.0) {
            Spacer()
                .frame(width: windowSize.width, height: max(0.0, topCellHeight - previewContentSize.height))
            scrollContent
                .frame(width: windowSize.width, height: previewContentSize.height)
        }
        QASplitedPagesSettingsView(markdownState: $markdownState, selectedFontSize: $fontSize, windowSize: $windowSize)
            .environment(viewModel)
            .safeAreaInset(edge: .top, alignment: .center, spacing: 0.0) {
                ScrollView { contentView }
                    .environment(\.colorScheme, .light)
                    .frame(width: windowSize.width, height: topCellHeight)
            }
            .toolbar(content: toolbarContent)
            .disabled(isDisabled)
            .alert("Generation Failed", isPresented: viewModel.binding(for: \.isShowingShareFailuredAlert), actions: {
                Button("OK") {}
            })
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear(perform: SVProgressHUD.dismiss)
            .environment(\.dynamicTypeSize, .medium)
            .onChange(of: viewModel.selectedTemplate, initial: true) { _, newValue in
                viewModel.updateSuggestedPagePadding(pageWidth: windowSize.width)
                markdownState.theme = .concise
                markdownState.backgroundColor = Color(newValue.textBackgroundColor).opacity(0)
            }
            .onChange(of: viewModel.pageRotation, initial: true) { _, _ in
                viewModel.updateSuggestedPagePadding(pageWidth: windowSize.width)
                markdownState.theme = .concise
            }
            .sheet(item: $renderingResult) { result in
                QASplitedPagesResultView(pdfURL: result.url, pdfData: result.data)
            }
    }
    
    var scrollContent: some View {
        VStackLayout(alignment: .center, spacing: 0.0) {
            QATemplateRotationView(template: viewModel.selectedTemplate, pageRotation: viewModel.pageRotation, horizontalPadding: viewModel.horizontalPagePadding) {
                markdownContent
            }
            .scrollBackgroundColor(markdownState.backgroundColor)
            .scrollEdgeColor(.top, .bottom, color: markdownState.backgroundColor)
            .environment(\.colorScheme, .light)
        }
    }
    
    var markdownContent: QARenderingContentView {
        QARenderingContentView(viewModel: viewModel, controller: $markdownState, titleCellSize: $titleCellSize, isDisabled: $isDisabled)
    }
    
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
            Button("Generate", action: generate)
                .menuStyle(.button)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(Color.teal)
                .disabled(isDisabled)
        }
    }
}

extension QAImageConvertSplitedPagesView {
    func generate() {
        self.isDisabled = true
        Task {
            SVProgressHUD.show()
            defer {
                SVProgressHUD.dismiss()
                self.isDisabled = false
            }
            guard let result = await fetchSplitResult() else {
                viewModel.isShowingShareFailuredAlert = true
                return
            }
            self.renderingResult = result
        }
    }
    
    private func fetchSplitResult() async -> RenderingResult? {
        let preferredSize = viewModel.pageRotation.size(width: windowSize.width)
        guard let layoutResult = QATemplateManager.current.renderingResult(for: viewModel.selectedTemplate, preferredSize: preferredSize) else {
            return nil
        }
        let textRectMinX = layoutResult.textRect.minX + viewModel.horizontalPagePadding
        
        let titleRenderer = ImageRenderer(content: self.markdownContent.titleCell.frame(width: titleCellSize.width, height: titleCellSize.height))
        
        titleRenderer.scale = 5.0
        titleRenderer.proposedSize = .init(titleCellSize)
        let titleCellImage = titleRenderer.uiImage
        let titleCellImageRect = (titleCellImage == nil) ? nil : CGRect.init(x: textRectMinX, y: layoutResult.textRect.minY + viewModel.verticalPagePadding, width: titleCellSize.width, height: titleCellSize.height)
        let pageImage = await layoutResult.totalImage()
        let newContentRect = layoutResult.textRect.inseting(
            top: viewModel.verticalPagePadding,
            bottom: viewModel.verticalPagePadding,
            //TODO: Check why the parameter 2.0 is being passed here.
            left: 2 * viewModel.horizontalPagePadding,
            right: 2 * viewModel.horizontalPagePadding
        )
        let config = DownTeX.ConvertConfiguration(
            fontSize: fontSize,
            pageSize: layoutResult.size,
            contentRect: newContentRect,
            allowTextOverflow: viewModel.allowTextOverflow,
            pageImage: pageImage,
            titleImage: titleCellImage,
            titleRect: titleCellImageRect
        )
        guard let data = try? await  DownTeX.current.convertToPDFData(markdown: viewModel.answerContent, config: config) else {
            return nil
        }
        guard let url = await URL.temporaryFileURL(data: data, fileName: viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled")), conformTo: .pdf) else {
            return nil
        }
        return .init(data: data, url: url)
    }
}

//MARK: - Settings View
struct QASplitedPagesSettingsView: View {
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Binding var markdownState: MarkdownState
    @Binding var selectedFontSize: DownTeX.FontSize
    @Binding var windowSize: CGSize
    var body: some View {
        VStack(alignment: .center, spacing: 0.0) {
            Divider()
            content
                .dynamicTypeSize(.small)
        }
        .background(Material.ultraThick, ignoresSafeAreaEdges: .all)
        .onChange(of: selectedFontSize, initial: true) { _, newValue in
            markdownState.fontSize = newValue.pointSize - 3.0
        }
        .onChange(of: viewModel.verticalPagePadding, initial: true, { _, newValue in
            markdownState.bottomPadding = newValue
        })
        .onChange(of: viewModel.horizontalPagePadding, initial: true, { _, newValue in
            markdownState.horizontalPadding = newValue
        })
    }
    
    var content: some View {
        List {
            let splitedSize = viewModel.pageRotation.size(width: windowSize.width)
            let layoutResult = QATemplateManager.current.pageRects(for: viewModel.selectedTemplate, preferredSize: splitedSize)
            let maximumVerticalPadding = 0.3 * (layoutResult?.layoutRect.height ?? 0.0)
            let maximumHorizontalPadding = 0.1 * (layoutResult?.layoutRect.width ?? 0.0)
            Section("Style") {
                QAImageConvertSettingLabel.usingWaterMarkLabel(viewModel: viewModel)
                QAImageConvertSettingLabel.usingTitleBorder(viewModel: viewModel)
                QAImageConvertSettingLabel.templateLabel(viewModel: viewModel)
                QAImageConvertSettingLabel.pageHorizontalPaddingLabel(viewModel: viewModel, markdownState: markdownState, maximumHeight: maximumHorizontalPadding)
                QAImageConvertSettingLabel.pageVerticalPaddingLabel(viewModel: viewModel, maximumHeight: maximumVerticalPadding)
                rotationLabel
                fontSizeLabel
                textOverflowLabel
            }
        }
    }
    
    var rotationLabel: some View {
        Picker("Page Aspect Ratio", selection: viewModel.binding(for: \.pageRotation)) {
            ForEach(QAPageRotation.allCases) { rotation in
                Text(rotation.title).tag(rotation)
            }
        }
    }
    
    var fontSizeLabel: some View {
        Picker("Text Size", selection: $selectedFontSize) {
            ForEach(DownTeX.FontSize.allCases) { size in
                Text("\(Int(size.pointSize)) pt").tag(size)
            }
        }
    }
    
    var textOverflowLabel: some View {
        Toggle("Try to Prevent Text Overflow", isOn: viewModel.binding(for: \.preventTextOverflow))
    }
}


//MARK: - Result Preview View
struct QASplitedPagesResultView: View {
    let pdfURL: URL
    let pdfData: Data
    
    @StateObject private var pdfState = PDFPreviewerModel()
    @State private var selectedPDFURL: ShareFileURL?
    @State private var selectedImagesURL: ShareFileURL?
    @State private var isShowingShareFailuredAlert = false
    @State private var windowSize = CGSize.zero
    @Environment(\.dismiss) var dismiss
    
    init(pdfURL: URL, pdfData: Data) {
        self.pdfURL = pdfURL
        self.pdfData = pdfData
    }
    
    var body: some View {
        NavigationStack {
            PDFPreviewer(model: pdfState)
                .ignoresSafeArea(.all, edges: .bottom)
                .task {
                    pdfState.themeColor = .default
                    pdfState.invertRenderingColor = false
                    await pdfState.loadDocument(from: pdfData)
                    pdfState.themeColor = .init(backgroundColor: .clear)
                    pdfState.documentScale = 1.0
                }
                .navigationTitle("Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbarContent)
                .fileShareSheet(item: $selectedPDFURL)
                .fileShareSheet(item: $selectedImagesURL)
                .alert("Share Failed", isPresented: $isShowingShareFailuredAlert) {
                    Button("OK") {}
                }
        }
        .onGeometryChange(body: { windowSize = $0 })
    }
    
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
            Menu("Share") {
                Button("Share as PDF", systemImage: "document", action: shareAsPDF)
                Button("Share as Images", systemImage: "photo.on.rectangle") {
                    Task { await shareImages() }
                }
            }
            .menuStyle(.button)
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.teal)
        }
    }
    
    private func shareAsPDF() {
        selectedPDFURL = .init(url: pdfURL)
    }
    
    private func shareImages() async {
        defer { SVProgressHUD.dismiss() }
        SVProgressHUD.show()
        let urls: [URL] = await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(data: pdfData) else {
                return []
            }
            var urls = [URL]()
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { return [] }
                let image = await page.image(width: windowSize.width, contentScale: 3.0)
                guard let data = image.pngData() else {
                    return []
                }
                guard let url = await URL.temporaryFileURL(data: data, fileName: #localized("Image") + "\(index + 1)", conformTo: .png) else {
                    return []
                }
                urls.append(url)
            }
            return urls
        }
        if urls.isEmpty {
            isShowingShareFailuredAlert = true
            return
        }
        selectedImagesURL = .init(urls: urls)
    }
}
