//
//  QAPageSettingsLabel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI
import MarkdownView

struct QAImageConvertSettingLabel {
    private init() {}
    @MainActor
    static func pageHorizontalPaddingLabel(viewModel: QAViewModel, markdownState: MarkdownState, maximumHeight: CGFloat) -> some View {
        VStack {
            HStack {
                Text("Horizontal Page Margins")
                Spacer()
                Text(String(format: "%.1f", viewModel.horizontalPagePadding) + " pt")
                    .foregroundStyle(.secondary)
            }
            @Bindable var state = viewModel
            Slider(value: $state.horizontalPagePadding, in: 0.0...max(maximumHeight, 10.0), step: 1.0, label: {  }, minimumValueLabel: { Image(systemName: "number").imageScale(.small) }, maximumValueLabel: { Image(systemName: "number").imageScale(.medium) })
        }
    }
    
    @MainActor
    static func pageVerticalPaddingLabel(viewModel: QAViewModel, maximumHeight: CGFloat? = nil) -> some View {
        VStack {
            HStack {
                Text("Vertical Page Margins")
                Spacer()
                Text(String(format: "%.1f", viewModel.verticalPagePadding) + " pt")
                    .foregroundStyle(.secondary)
            }
            @Bindable var state = viewModel
            Slider(value: $state.verticalPagePadding, in: 0...max(maximumHeight ?? 100.0, 10.0), step: 1.0, label: {  }, minimumValueLabel: { Image(systemName: "number").imageScale(.small) }, maximumValueLabel: { Image(systemName: "number").imageScale(.medium) })
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
