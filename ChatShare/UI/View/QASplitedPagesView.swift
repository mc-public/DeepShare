//
//  QASplitedPagesView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI
import MarkdownView
import SVProgressHUD

struct QASplitedPagesView: QANavigationLeaf {
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @State var markdownState = MarkdownState()
    @State var titleCellSize = CGSize.zero
    @State var windowSize = CGSize.zero
    @State var isDisabled = true
    
    var content: some View {
        let preferredSize = viewModel.pageRotation.size(width: windowSize.width)
        let containerLayout = QATemplateManager.current.pageRects(for: viewModel.selectedTemplate, preferredSize: preferredSize)
        let previewContentSize = containerLayout?.pageSize ?? .zero
        let topCellHeight = 0.7 * windowSize.height
        let contentView = VStack(spacing: 0.0) {
            Spacer()
                .frame(height: max(0.0, topCellHeight - previewContentSize.height))
            scrollContent
                .frame(height: previewContentSize.height)
        }
        QASplitedPagesSettingsView(markdownState: $markdownState)
            .disabled(isDisabled)
            .environment(viewModel)
            .safeAreaInset(edge: .top, alignment: .center, spacing: 0.0) {
                ScrollView { contentView }
                    .environment(\.colorScheme, .light)
                    .frame(width: windowSize.width, height: topCellHeight)
            }
            .toolbar(content: toolbarContent)
            .onGeometryChange(body: { windowSize = $0 })
            .alert("Share Failured", isPresented: viewModel.binding(for: \.isShowingShareFailuredAlert), actions: {
                Button("OK") {}
            })
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .fileShareSheet(item: viewModel.binding(for: \.imageResult))
            .fileShareSheet(item: viewModel.binding(for: \.pdfResult))
            .onDisappear(perform: SVProgressHUD.dismiss)
            .environment(\.dynamicTypeSize, .medium)
            .onChange(of: viewModel.selectedTemplate, initial: true) { _, newValue in
                markdownState.theme = .concise
                markdownState.backgroundColor = Color(newValue.textBackgroundColor).opacity(0)
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
            Spacer()
        }
    }
    
    var markdownContent: QARenderingContentView {
        QARenderingContentView(viewModel: viewModel, controller: $markdownState, titleCellSize: $titleCellSize, isDisabled: $isDisabled)
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
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

extension QASplitedPagesView {
    func generate() {
        self.isDisabled = true
        Task {
            SVProgressHUD.show()
            defer {
                SVProgressHUD.dismiss()
            }
            guard let url = await fetchSplitResult() else {
                self.isDisabled = false
                viewModel.isShowingShareFailuredAlert = true
                return
            }
            //viewModel.imageResult = ShareFileURL(url: url)
            try? await Task.sleep(for: .microseconds(500))
            self.isDisabled = false
        }
    }
    
    private func fetchSplitResult() async -> URL? {
        let preferredSize = viewModel.pageRotation.size(width: windowSize.width)
        guard let layoutResult = QATemplateManager.current.renderingResult(for: viewModel.selectedTemplate, preferredSize: preferredSize) else {
            return nil
        }
        let titleRenderer = ImageRenderer(content: self.markdownContent.titleCell.frame(width: titleCellSize.width, height: titleCellSize.height))
        titleRenderer.scale = 3.0
        titleRenderer.proposedSize = .init(titleCellSize)
        guard let titleCellImage = titleRenderer.uiImage else {
            return nil
        }
        return nil
    }
}

struct QASplitedPagesSettingsView: View {
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Binding var markdownState: MarkdownState
    @State private var selectedFontSize: DownTeX.FontSize = .pt12
    var body: some View {
        VStack(alignment: .center, spacing: 0.0) {
            Divider()
            content
                .dynamicTypeSize(.small)
        }
        .background(Material.ultraThick, ignoresSafeAreaEdges: .all)
        .onChange(of: selectedFontSize, initial: true) { _, newValue in
            markdownState.fontSize = newValue.pointSize
        }
    }
    
    var content: some View {
        List {
            Section("Style") {
                QAPageSettingLabel.usingWaterMarkLabel(viewModel: viewModel)
                QAPageSettingLabel.usingTitleBorder(viewModel: viewModel)
                QAPageSettingLabel.templateLabel(viewModel: viewModel)
                QAPageSettingLabel.pageHorizontalPaddingLabel(markdownController: markdownState)
                rotationLabel
                fontSizeLabel
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
}
