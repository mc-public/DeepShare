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

//MARK: - QA Result Display (Rendering) View

struct QARenderingView: QANavigationLeaf {
    
    class Storage<Value> {
        var value: Value
        init(value: Value) {
            self.value = value
        }
    }
    
    @State var controller = MarkdownState()
    @State var windowSize: CGSize = .zero
    @State var textLayoutStorage: Storage<CGSize> = .init(value: .zero)
    @State var textLayoutSize = CGSize.zero
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    
    var navigationTitleColor: Color {
        controller.backgroundColor.luminance < 0.5 ? .white : .black
    }
    
    var content: some View {
        let templatePreferredSize = QATemplateManager.current.preferredSize(for: viewModel.selectedTemplate, preferredWidth: windowSize.width, preferredTextHeight: textLayoutSize.height)
        let containerLayout = QATemplateManager.current.pageRects(for: viewModel.selectedTemplate, preferredSize: templatePreferredSize)
        let totalSize = containerLayout?.pageSize ?? .zero
        let layoutRect = containerLayout?.layoutRect ?? .zero
        ScrollView(.vertical) {
            Frame(totalSize, alignment: .top) {
                VStack(alignment: .center, spacing: 0.0) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: containerLayout?.topRect.height ?? 0.0)
                    Frame(width: max(0.0, layoutRect.width - viewModel.horizontalPagePadding), height: layoutRect.height, alignment: .top) {
                        VStackLayout(alignment: .center, spacing: 0.0) {
                            verticalStack()
                        }
                    }
                }
            }
            .background {
                QATemplateView(template: viewModel.selectedTemplate, size: totalSize)
            }
        }
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
            controller.backgroundColor = Color(newValue.textBackgroundColor)
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
            ChatModelInfoCell(chatModel: viewModel.selectedChatAI)
                .font(.preferredFont(relativeMetric: controller.fontSize, style: .footnote))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, length: 10.0)
        .padding(.bottom, 5.0)
        .withCornerBackground(radius: 10.0, style: Material.ultraThinMaterial)
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
            }
            Markdown(state: $controller)
                .onRendered(SVProgressHUD.dismiss)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .hidden(controller.isRenderingContent)
        .onGeometryChange(body: {
            textLayoutSize = $0
        })
        .fixedSize(horizontal: false, vertical: true)
    }
    
    func onAppear() {
        controller.text = viewModel.answerContent
        controller.backgroundColor = .clear
        SVProgressHUD.show()
    }
}

extension QARenderingView {
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
        guard let image = await controller.container.contentImage(width: nil) else {
            return nil
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
                themeLabel
                fontSizeLabel
                pageHorizontalPaddingLabel
                if markdownController.theme.colorSupport == .dynamic {
                    backgroundColorLabel
                }
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
