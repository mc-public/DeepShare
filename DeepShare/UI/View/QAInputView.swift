//
//  QAInputView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import QuickLook
import SVProgressHUD
import Localization

//MARK: - QAInputView

struct QAInputView: QANavigationLeaf {
    
    typealias Target = Never
    
    @Environment(QAViewModel.self) var model: QAViewModel
    @Environment(QANavigationModel.self) var navigation: QANavigationModel
    @Environment(\.dismiss) var dismiss
    
    enum BlockFocusState: Hashable {
        case questionBlock, answerBlock
    }
    
    @FocusState private var blockFocusState: BlockFocusState?
    @State private var isDisabled = false
    
    var content: some View {
        GeometryReader { proxy in
            VStackLayout(spacing: 0.0) {
                textInputStack(height: proxy.size.height)
            }
        }
        .onDisappear(perform: { model.listSelectedModels = .init() })
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.listBackgroundColor, ignoresSafeAreaEdges: .all)
        .toolbar(content: toolbarContent)
        .navigationBarBackButtonHidden()
        .disabled(isDisabled)
        .fileImporter(isPresented: model.binding(for: \.isShowingMarkdownImporter), allowedContentTypes: [.text], onCompletion: { result in
            Task { await loadImportMarkdownURL(result: result) }
        })
        .quickLookPreview(model.binding(for: \.docxConvertResultURL))
        .sheet(isPresented: model.binding(for: \.isShowingSinglePageSheet)) {
            QAImageConvertLongPageView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: model.binding(for: \.isShowingSplitedPageSheet)) {
            QAImageConvertSplitedPagesView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: model.binding(for: \.isShowingTextConvertSheet)) {
            QATextConvertView()
                .interactiveDismissDisabled()
        }
    }
    
    //MARK: - Input Blocks
    var questionBlock: some View {
        HStack(alignment: .top, spacing: 0.0) {
            circleImage(image: Image(systemName: "person.fill.questionmark").foregroundStyle(HierarchicalShapeStyle.secondary), backgroundStyle: Color.listCellBackgroundColor, width: 40.0)
                .padding(.horizontal)
            TextEditor(text: model.binding(for: \.questionContent))
                .focused($blockFocusState, equals: BlockFocusState.questionBlock)
                .textEditorPrompt(text: model.questionContent, #localized("Enter the title here…"), style: Color.gray.opacity(0.3))
                .font(.title2)
                .fontWidth(.condensed)
                .fontWeight(.semibold)
                .padding(.horizontal, 3)
                .withCornerBackground(radius: 13.0, style: Color.listCellBackgroundColor)
                .padding(.trailing)
                .padding(.trailing)
        }
    }
    
    var answerBlock: some View {
        HStack(alignment: .top, spacing: 0.0) {
            circleImage(image: Image(systemName: "person.fill.checkmark").foregroundStyle(HierarchicalShapeStyle.secondary), backgroundStyle: Color.listCellBackgroundColor, width: 40.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                MenuPicker(source: QAChatAIModel.allCases, selectedItem: model.binding(for: \.selectedChatAI)) { item in
                    Text(item.rawValue)
                } menuLabel: {
                    Text(model.selectedChatAI.rawValue)
                        .underline()
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                }
                .menuStyle(.button)
                .foregroundStyle(.secondary)
                TextEditor(text: model.binding(for: \.answerContent))
                    .focused($blockFocusState, equals: BlockFocusState.answerBlock)
                    .textEditorPrompt(text: model.answerContent, #localized("Enter the content in Markdown format here…"), style: Color.gray.opacity(0.3))
                    .font(.title2)
                    .fontWidth(model.answerContent.isEmpty ? .condensed : .standard)
                    .fontWeight(model.answerContent.isEmpty ? .semibold : .regular)
                    .padding(.horizontal, 3)
                    .withCornerBackground(radius: 13.0, style: Color.listCellBackgroundColor)
                    .padding(.trailing)
                    .padding(.trailing)
            }
        }
    }
    
    @ViewBuilder
    func textInputStack(height: CGFloat) -> some View {
        VStackLayout(spacing: 0.0) {
            questionBlock
                .padding(.vertical)
                .frame(height: 0.3 * height)
            answerBlock
                .padding(.top)
                .padding(.bottom)
                .frame(height: 0.7 * height)
        }
    }
    
    func circleImage<S: ShapeStyle>(image: some View, backgroundStyle: S, width: CGFloat) -> some View {
        Circle()
            .fill(backgroundStyle)
            .overlay(alignment: .center) { image }
            .frame(width: width, height: width, alignment: .center)
    }
}

//MARK: - Toolbar

extension QAInputView {
    
    @ViewBuilder
    var shareMenu: some View {
        Menu {
            Button("Convert to Long Image", systemImage: "photo") {
                model.isShowingSinglePageSheet = true
            }
            Button("Convert to Image Slices or PDF Format (.pdf)", systemImage: "photo.stack") {
                model.isShowingSplitedPageSheet = true
            }
            Button("Convert to Office Open XML Format (.docx)", systemImage: "richtext.page") {
                convertToDocx()
            }
            Button("Convert to Other Text Formats", systemImage: "text.page") {
                model.isShowingTextConvertSheet = true
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(model.isContentEmpty ? Color.deepOrange.opacity(0.6) : Color.deepOrange)
        }
        .menuStyle(.button)
        .disabled(model.isContentEmpty)
        
    }
    
    @ViewBuilder
    var ellipsisMenu: some View {
        Menu {
            Button("Paste Full Text From Clipboard", systemImage: "document.on.clipboard", action: importFromPasteboard)
                .disabled(!model.isPasteboardHasContent || !model.isContentEmpty)
            Button("Import Full Text From Markdown File (.md)", systemImage: "square.and.arrow.down", action: importFromFile)
                .disabled(!model.isContentEmpty)
            Divider()
            Button("Clear All Content", systemImage: "trash", role: .destructive, action: model.clearContent)
                .disabled(model.isContentEmpty)
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(Color.deepOrange)
        }
        .menuStyle(.button)
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                navigation.popLast(dismiss)
            } label: {
                Image(systemName: "list.bullet")
                    .imageScale(.large)
            }
            .foregroundStyle(Color.deepOrange)
        }
        ToolbarItem(placement: .navigation) {
            Text(ChatShareApp.Name)
                .font(.title2)
                .fontWeight(.medium)
                .fontDesign(.serif)
                .foregroundStyle(Color.deepOrange)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack(alignment: .lastTextBaseline) {
                Group {
                    shareMenu
                    ellipsisMenu
                }
                .withCondition { view in
                    if blockFocusState != nil {
                        Button("Done") { self.blockFocusState = nil }
                            .foregroundStyle(Color.deepOrange)
                            .bold()
                    } else { view }
                }
                .padding(.trailing, 5.0)
            }
            .animation(nil, value: blockFocusState)
        }
    }
}

extension QAInputView {
    
    private func loadImportMarkdownURL(result: Result<URL, any Error>) async {
        switch result {
            case .success(let url):
                let extensionName = url.pathExtension.lowercased()
                guard ["md", "txt"].contains(extensionName) else {
                    await SVProgressHUD.displayingFailuredInfo(title: #localized("Unsupported File Format"))
                    return
                }
                do {
                    try await model.loadMarkdownContent(url: url)
                    await SVProgressHUD.displayingSuccessInfo(title: #localized("Import Successful"))
                } catch { await SVProgressHUD.displayingFailuredInfo(title: error.localizedDescription) }
            case .failure(let failure):
                await SVProgressHUD.displayingFailuredInfo(title: failure.localizedDescription)
        }
    }
    
    private func importFromFile() {
        model.isShowingMarkdownImporter = true
    }
    
    private func importFromPasteboard() {
        Task {
            await model.pasteFullContent()
            await SVProgressHUD.displayingSuccessInfo(title: #localized("Paste Completed"))
        }
    }
    
    private func convertToDocx() {
        isDisabled = true
        SVProgressHUD.show()
        Task {
            defer { isDisabled = false }
            let content = self.model.normalizedQAMarkdownContent()
            guard let data = try? await DownTeX.current.convertToDocx(markdownString: content),
                  let url = await URL.temporaryFileURL(
                    data: data,
                    fileName: model.questionContent.sanitizedFileName(empty: #localized("Untitled")),
                    extensionName: "docx"
                  ) else {
                await SVProgressHUD.displayingFailuredInfo(title: #localized("Conversion Failed"))
                return
            }
            model.docxConvertResultURL = url
            await SVProgressHUD.dismiss()
        }
    }
}
