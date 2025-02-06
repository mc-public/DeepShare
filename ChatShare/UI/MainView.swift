//
//  ContentView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import SVProgressHUD


struct MainView: View {
    @State var model = MainViewModel()
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStackLayout(spacing: 0.0) {
                    self.textInputStack(height: proxy.size.height)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarRole(.browser)
                .sheet(isPresented: $model.isShowingPreviewer) {
                    ChatResultDisplayView(model: $model)
                }
            }
            .background(Color.listBackgroundColor, ignoresSafeAreaEdges: .all)
            .toolbar(content: toolbarContent)
        }
    }
    
    var questionBlock: some View {
        HStack(alignment: .top, spacing: 0.0) {
            self.circleImage(image: Image(systemName: "person.fill.questionmark").foregroundStyle(HierarchicalShapeStyle.secondary), backgroundStyle: Color.listCellBackgroundColor, width: 40.0)
                .padding(.horizontal)
            TextArea(text: model.binding(for: \.questionContent), prompt: "请输入问题内容", promptColor: Color.gray.opacity(0.3), initalFocused: true)
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
            self.circleImage(image: Image(systemName: "person.fill.checkmark").foregroundStyle(HierarchicalShapeStyle.secondary), backgroundStyle: Color.listCellBackgroundColor, width: 40.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                MenuPicker(source: ChatModel.allCases, selectedItem: $model.chatModel) { item in
                    Text(item.rawValue)
                } menuLabel: {
                    Text(model.chatModel.rawValue)
                        .underline()
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .fontWidth(.compressed)
                }
                .menuStyle(.button)
                .foregroundStyle(.secondary)
                
                TextArea(text: model.binding(for: \.answerContent), prompt: "请输入Markdown格式的回答", promptColor: Color.gray.opacity(0.3), initalFocused: false)
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

extension MainView {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(systemImage: "list.bullet", scale: .large) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .foregroundStyle(Color.deepOrange)
        }
        ToolbarItem(placement: .navigation) {
            Text("ChatShare")
                .font(.title2)
                .fontWeight(.medium)
                .fontDesign(.serif)
                .foregroundStyle(Color.deepOrange)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("转换为图片") {
                model.answerContent.replace("\\[", with: "$$")
                model.answerContent.replace("\\]", with: "$$")
                model.isShowingPreviewer = true
            }
            .disabled(model.isContentEmpty)
            .buttonStyle(.plain)
            .foregroundStyle(Color.deepOrange)
            .padding(5)
        }
    }
}
