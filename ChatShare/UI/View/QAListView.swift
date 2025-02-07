//
//  HistoryView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

struct QAListView: QANavigationComponent {
    
    typealias Target = QAInputView
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(QANavigationModel.self) var navigationModel: QANavigationModel
    @Environment(\.dismiss) var dismiss
    
    var content: some View {
        List {
            QANavigationLink(Target.self) {
                Text("导航到目标")
            }
        }
        .navigationTitle(ChatShareApp.Name)
    }
    
}
