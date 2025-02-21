//
//  QAInputView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import Localization

struct QAInputView: QANavigationLeaf {
    
    typealias Target = Never
    
    @Environment(QAViewModel.self) var model: QAViewModel
    @Environment(QANavigationModel.self) var navigation: QANavigationModel
    @Environment(\.dismiss) var dismiss
    
    enum BlockFocusState: Hashable {
        case questionBlock, answerBlock
    }
    
    @FocusState private var blockFocusState: BlockFocusState?
    
    var content: some View {
        GeometryReader { proxy in
            VStackLayout(spacing: 0.0) {
                textInputStack(height: proxy.size.height)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.listBackgroundColor, ignoresSafeAreaEdges: .all)
        .toolbar(content: toolbarContent)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: model.binding(for: \.isShowingSinglePageSheet)) {
            NavigationStack(root: QASinglePageView.init)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: model.binding(for: \.isShowingSplitedPageSheet)) {
            NavigationStack(root: QASplitedPagesView.init)
                .interactiveDismissDisabled()
        }
    }
    
    
    
    var questionBlock: some View {
        HStack(alignment: .top, spacing: 0.0) {
            circleImage(image: Image(systemName: "person.fill.questionmark").foregroundStyle(HierarchicalShapeStyle.secondary), backgroundStyle: Color.listCellBackgroundColor, width: 40.0)
                .padding(.horizontal)
            TextEditor(text: model.binding(for: \.questionContent))
                .focused($blockFocusState, equals: BlockFocusState.questionBlock)
                .textEditorPrompt(text: model.questionContent, #localized("Enter the question content here"), style: Color.gray.opacity(0.3))
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
                    .textEditorPrompt(text: model.answerContent, #localized("Enter the answer in Markdown format here"), style: Color.gray.opacity(0.3))
                    .font(.title2)
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
            .overlay(alignment: .center) {
                image
            }
            .frame(width: width, height: width, alignment: .center)
    }
}

extension QAInputView {
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
            HStack(alignment: .firstTextBaseline) {
                Menu {
                    Button("Convert To Long Image", systemImage: "photo") {
                        model.isShowingSinglePageSheet = true
                    }
                    Button("Convert to Short Image Slices", systemImage: "photo.stack") {
                        model.isShowingSplitedPageSheet = true
                    }
                } label: {
                    Text("Convert")
                        .bold()
                        .foregroundStyle(model.isContentEmpty ? Color.deepOrange.opacity(0.6) : Color.deepOrange)
                }
                .menuStyle(.button)
                .disabled(model.isContentEmpty)
                .padding(.trailing, length: 5)
                
                if blockFocusState != nil {
                    Button("Done") { self.blockFocusState = nil }
                        .foregroundStyle(Color.deepOrange)
                        .bold()
                        .padding(.trailing, length: 5)
                }
            }
            .animation(nil, value: blockFocusState)
        }
    }
}
