//
//  QANavigationComponent.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

/// A button used to perform navigation actions in views that conform to `QANavigationComponent`.
struct QANavigationLink<Target, Label>: View where Target: QANavigationComponent, Label: View {
    private let targetType: Target.Type
    private let label: () -> Label
    /// Create a button for performing navigation actions.
    ///
    /// - Parameter target: The type of the target view for navigation.
    /// - Parameter label: The label of the navigation button.
    init(_ target: Target.Type, @ViewBuilder label: @escaping () -> Label) where Label: View {
        self.targetType = target
        self.label = label
    }
    
    var body: some View {
        NavigationLink(value: QANavigationTarget(target: targetType.self)) {
            self.label()
        }
    }
}

/// The data structure used to represent navigation targets in a navigation model.
struct QANavigationTarget: Hashable {
    /// The view type corresponding to the currently stored navigation target.
    let target: any QANavigationComponent.Type
    private let hash: String
    
    fileprivate init(target: any QANavigationComponent.Type) {
        self.target = target
        self.hash = "\(target.self)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
    
    static func == (lhs: QANavigationTarget, rhs: QANavigationTarget) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

/// The navigation components used in the QA navigation stack.
@MainActor
protocol QANavigationComponent: View {
    /// The content type about the navigation component.
    associatedtype Content: View
    init()
    /// The view component
    var content: Content { get }
}

extension QANavigationComponent {
    var body: some View {
        content
            .navigationDestination(for: QANavigationTarget.self) { target in
                AnyView(
                    target.target.init()
                        .environment(QANavigationModel.current)
                        .environment(QAViewModel.current)
                )
            }
    }
    /// The navigation target corresponding to the current navigation component.
    static var NavigationTarget: QANavigationTarget {
        QANavigationTarget.init(target: self)
    }
}


