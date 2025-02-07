//
//  QANavigationModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI
import Observation

/// The data structure used to represent the path of a navigation component.
@MainActor @Observable
final class QANavigationModel {
    /// The navigation path about current navigation model.
    var navigationPath: [QANavigationTarget] {
        didSet {
            if let last = navigationPath.last, navigationPath.count(where: { $0 == last }) >= 2 {
                fatalError("[BaseFramework][\(Self.self)] Do not pass components with `duplicate target`, as this can cause navigation state anomalies.")
            }
        }
    }
    
    /// The shared navigation model instance.
    static let current = QANavigationModel()
    
    /// Create an empty navigation model.
    private init() {
        self.navigationPath = [QAInputView.NavigationTarget]
    }
    
    /// Remove the last view from the current navigation stack.
    func popLast() {
        _ = self.navigationPath.popLast()
    }
}
