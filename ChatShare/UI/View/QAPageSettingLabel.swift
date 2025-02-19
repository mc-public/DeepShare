//
//  QAPageSettingsLabel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI
import MarkdownView

struct QAPageSettingLabel {
    private init() {}
    @MainActor
    static func pageHorizontalPaddingLabel(markdownController: MarkdownState) -> some View {
        VStack {
            HStack {
                Text("Horizontal Page Margins")
                Spacer()
                Text(String(format: "%.1f", markdownController.horizontalPadding) + " pt")
                    .foregroundStyle(.secondary)
            }
            @Bindable var state = markdownController
            Slider(value: $state.horizontalPadding, in: markdownController.horizontalPaddingRange, step: 1.0, label: {  }, minimumValueLabel: { Image(systemName: "number").imageScale(.small) }, maximumValueLabel: { Image(systemName: "number").imageScale(.medium) })
        }
    }
    
    @MainActor
    static func usingWaterMarkLabel(viewModel: QAViewModel) -> some View {
        Toggle("Author", isOn: viewModel.binding(for: \.usingWaterMark))
    }
    
    @MainActor
    static func usingTitleBorder(viewModel: QAViewModel) -> some View {
        Toggle("Title Background", isOn: viewModel.binding(for: \.usingTitleBorder))
    }
    
    @MainActor
    static func templateLabel(viewModel: QAViewModel) -> some View {
        Picker("Template", selection: viewModel.binding(for: \.selectedTemplate)) {
            ForEach(QATemplateManager.current.allTemplates) { template in
                Text(template.title).tag(template)
            }
        }
    }
}
