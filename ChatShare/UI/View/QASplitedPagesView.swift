//
//  QASplitedPagesView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import SwiftUI

struct QASplitedPagesView: QANavigationLeaf {
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    var content: some View {
        QATemplateRotationView(template: viewModel.selectedTemplate, pageRotation: viewModel.pageRotation, horizontalPadding: viewModel.horizontalPagePadding) {
            Spacer()
        }
    }
}

extension QASplitedPagesView {
    
    
}
