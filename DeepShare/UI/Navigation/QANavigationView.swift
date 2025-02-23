//
//  QANavigationView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

/// The first view of the navigation stack about the `QANavigationView`.
struct QANavigationView: QANavigationRoot {
    @State var navigationModel = QANavigationModel.current
    @State var viewModel = QAViewModel.current
    @State var dataManager = QADataManager.current
    var content: some View {
        QAListView()
            .environment(navigationModel)
            .environment(viewModel)
            .environment(dataManager)
    }
}
