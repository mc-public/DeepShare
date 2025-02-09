//
//  QARenderingView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import MarkdownView
import SVProgressHUD
@_spi(Advanced) import SwiftUIIntrospect
import WebKit
import Localization

//MARK: - QA Result Display (Rendering) View

struct QARenderingView: QANavigationLeaf {
    
    static let isUsingSheet: Bool = false
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @State private var isLoading: Bool = true
    @State private var contentSize: CGSize = .zero
    @State private var contentWebView: MarkdownView.WebView?
    
    @ViewBuilder
    var content: some View {
        GeometryReader { proxy in
            let scrollView = ScrollView(.vertical, content: verticalStack)
                .toolbar {
                    self.toolbarContent(width: proxy.size.width)
                }
            if Self.isUsingSheet {
                NavigationStack { scrollView }
            } else {
                scrollView
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .fileShareSheet(item: viewModel.binding(for: \.imageResult))
        .fileShareSheet(item: viewModel.binding(for: \.pdfResult))
    }
    
    @ViewBuilder
    func verticalStack() -> some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            if !viewModel.questionContent.isEmpty {
                Group {
                    Text(viewModel.questionContent)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWidth(.condensed)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    ChatModelInfoCell(chatModel: viewModel.selectedChatAI)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 5.0)
                }
            }
            MarkdownView(viewModel.answerContent)
                .onRendered { _ in
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        isLoading = false
                        await SVProgressHUD.dismiss()
                    }
                }
                .withWebView { webView in
                    contentWebView = webView
                }
                .border(.black, width: 1.0)
                .padding(.horizontal, 10.0)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .hidden(isLoading)
        .onAppear {
            isLoading = true
            SVProgressHUD.show()
        }
        .onGeometryChange { size in
            self.contentSize = size
        }
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
        guard let contentWebView else { return nil }
        guard let image = await contentWebView.contentImage(width: nil) else {
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
        guard let contentWebView else {
            return nil
        }
        Task {
            _ = await contentWebView.splitToImages()
        }
        return nil
    }
    
    func fetchPDFResult() async -> URL? {
        guard let contentWebView else { return nil }
        guard let data = await contentWebView.contentPDFData(width: nil) else { return nil }
        let fileName = viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled"))
        guard let pdfURL = await URL.temporaryFileURL(data: data, fileName: fileName, conformTo: .pdf) else {
            return nil
        }
        return pdfURL
    }
}

//MARK: - Chat Robot Display Cell
struct ChatModelInfoCell: View {
    let chatModel: QAChatAIModel
    var body: some View {
        HStackLayout(alignment: .firstTextBaseline) {
            Image(systemName: "checkmark.icloud.fill")
                .foregroundStyle(.green)
                .font(.footnote)
            Text(chatModel.rawValue)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
        }
    }
}
