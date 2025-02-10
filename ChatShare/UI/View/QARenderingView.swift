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
    
    @State var controller = MarkdownState()
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    
    var content: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                verticalStack()
            }
            .scrollIndicatorsStyle(.black)
            .scrollIndicatorsFlash(onAppear: true)
            .environment(\.colorScheme, .light)
            .toolbar {
                self.toolbarContent(width: proxy.size.width)
            }
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0.0) {
                QARenderingSettingsView(markdownController: $controller)
                    .frame(maxWidth: .infinity, maxHeight: 0.4 * proxy.size.height)
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .fileShareSheet(item: viewModel.binding(for: \.imageResult))
        .fileShareSheet(item: viewModel.binding(for: \.pdfResult))
        .onAppear(perform: onAppear)
        .onDisappear(perform: SVProgressHUD.dismiss)
        .environment(\.dynamicTypeSize, .medium)
    }
    
    @ViewBuilder
    func verticalStack() -> some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            if !viewModel.questionContent.isEmpty {
                Group {
                    Text(viewModel.questionContent)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .font(.preferredFont(relativeMetric: controller.fontSize, style: .title1))
                        .fontWidth(.condensed)
                        .fontWeight(.bold)
                        .padding(.horizontal, controller.horizontalPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top)
                    ChatModelInfoCell(chatModel: viewModel.selectedChatAI)
                        .font(.preferredFont(relativeMetric: controller.fontSize, style: .footnote))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 5.0)
                }
                .background(controller.backgroundColor, ignoresSafeAreaEdges: .all)
            }
            Markdown(state: $controller)
                .onRendered(SVProgressHUD.dismiss)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .hidden(controller.isRenderingContent)
    }
    
    func onAppear() {
        controller.text = viewModel.answerContent
        SVProgressHUD.show()
    }
}

extension QARenderingView {
    @ToolbarContentBuilder
    func toolbarContent(width: CGFloat) -> some ToolbarContent {
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
                        //                        viewModel.imageResult = await fetchSplitedImage()
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
                if markdownController.theme.colorSupport == .dynamic {
                    backgroundColorLabel
                }
                pageHorizontalPaddingLabel
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
        ColorPicker("Background Color", selection: markdownController.binding(for: \.backgroundColor), supportsOpacity: false)
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
            Slider(value: $markdownController.horizontalPadding, in: 0...100.0, step: 1.0, label: {  }, minimumValueLabel: { Image(systemName: "number").imageScale(.small) }, maximumValueLabel: { Image(systemName: "number").imageScale(.medium) })
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
