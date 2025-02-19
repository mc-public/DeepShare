//
//  QARenderingContentView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI
import MarkdownView
import SVProgressHUD

struct QARenderingContentView: View {
    
    var viewModel: QAViewModel
    @Binding var controller: MarkdownState
    @Binding var titleCellSize: CGSize
    @Binding var isDisabled: Bool
    
    @ViewBuilder
    var body: some View {
        VStackLayout(alignment: .leading, spacing: 0.0) {
            if !viewModel.questionContent.isEmpty {
                titleCell
                    .onGeometryChange(body: { titleCellSize = $0 })
            }
            Markdown(state: $controller)
                .onRendered({
                    SVProgressHUD.dismiss()
                    self.isDisabled = false
                })
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .hidden(controller.isRenderingContent)
        .onAppear {
            controller.text = viewModel.answerContent
            SVProgressHUD.show()
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
            if viewModel.usingWaterMark {
                ChatModelInfoCell(chatModel: viewModel.selectedChatAI)
                    .font(.preferredFont(relativeMetric: controller.fontSize, style: .footnote))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.top, length: 10.0)
        .padding(.bottom, viewModel.usingWaterMark ? 5.0 : 10.0)
        .withCondition(body: { view in
            if viewModel.usingTitleBorder {
                view.withCornerBackground(radius: 10.0, style: Material.ultraThinMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(viewModel.selectedTemplate.textBackgroundColor), ignoresSafeAreaEdges: .all)
            } else {
                view.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        })
        .padding(.horizontal, controller.horizontalPadding)
        .padding(.bottom)
        .padding(.top, viewModel.verticalPagePadding)
    }
}

//MARK: - Chat Robot Display Cell
struct ChatModelInfoCell: View {
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
