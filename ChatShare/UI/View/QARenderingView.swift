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

//MARK: - QA Result Display (Rendering) View

struct QARenderingView: QANavigationLeaf {
    
    static let isUsingSheet: Bool = false
    
    @Environment(QAViewModel.self) var model: QAViewModel
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
        .imageShareSheet(item: model.binding(for: \.imageResult), imageName: "image")
    }
    
    @ViewBuilder
    func verticalStack() -> some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            if !model.questionContent.isEmpty {
                Group {
                    Text(model.questionContent)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWidth(.condensed)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    ChatModelInfoCell(chatModel: model.selectedChatAI)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 5.0)
                }
            }
            MarkdownView(model.answerContent)
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
                Button("全文分享", systemImage: "square.and.arrow.up") {
                    Task {
                        model.imageResult = await fetchSingleImage()
                    }
                }
                Button("按段落划分后分享", systemImage: "square.and.arrow.up") {
                    Task {
                        model.imageResult = await fetchSplitedImage()
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
    
    func fetchSingleImage() async -> UIImage? {
        guard let contentWebView else { return nil }
        return await contentWebView.contentImage()
    }
    
    func fetchSplitedImage() async -> UIImage? {
        guard let contentWebView else {
            return nil
        }
        Task {
            //let image = await contentWebView.splitToImages()
            
        }
        return nil
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
