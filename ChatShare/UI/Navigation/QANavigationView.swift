//
//  QANavigationView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

/// The first view of the navigation stack about the `QANavigationView`.
struct QANavigationView: View {
    @State var navigationModel = QANavigationModel.current
    @State var viewModel = QAViewModel.current
    var body: some View {
        NavigationStack(path: navigationModel.binding(for: \.navigationPath)) {
            QAListView()
                .environment(navigationModel)
                .environment(viewModel)
        }
        
    }
}
