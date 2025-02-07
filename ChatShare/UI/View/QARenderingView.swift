//
//  ChatResultDisplayView.swift
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

struct QARenderingView: View {
    
    @Environment(QAViewModel.self) var model: QAViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isLoading: Bool = true
    @State private var contentSize: CGSize = .zero
    @State private var contentWebView: MarkdownView.WebView?
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ScrollView(.vertical) {
                    content
                }
                .navigationTitle("预览样式")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    self.toolbarContent(width: proxy.size.width)
                }
            }
        }
        .interactiveDismissDisabled()
        .imageShareSheet(item: model.binding(for: \.imageResult), imageName: "image")
    }
    
    var content: some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            Group {
                if !isLoading {
                    Text(self.model.questionContent)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .fontWidth(.condensed)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    ChatModelInfoCell(chatModel: self.model.selectedChatAI)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 5.0)
                }
                MarkdownView(self.model.answerContent)
                    .onRendered { _ in
                        isLoading = false
                        SVProgressHUD.dismiss()
                    }
                    .withWebView { webView in
                        contentWebView = webView
                    }
                    .padding(.horizontal, 10.0)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
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
        ToolbarItem(placement: .topBarLeading) {
            Button("取消", action: self.dismiss.callAsFunction)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("分享") {
                Button("全文分享", systemImage: "square.and.arrow.up") {
                    Task {
                        self.model.imageResult = await self.fetchSingleImage()
                    }
                }
                Button("按段落划分后分享", systemImage: "square.and.arrow.up") {
                    Task {
                        self.model.imageResult = await self.fetchSplitedImage()
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
            let image = await contentWebView.splitToImages()
            
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
