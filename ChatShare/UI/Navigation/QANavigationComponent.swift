//
//  QANavigationComponent.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

/// A button used to perform navigation actions in views that conform to `QANavigationComponent`.
struct QANavigationLink<Target, Label>: View where Target: QANavigationLeaf, Label: View {
    private let targetType: Target.Type
    private let label: () -> Label
    private let onCompletion: () -> ()
    /// Create a button for performing navigation actions.
    ///
    /// - Parameter target: The type of the target view for navigation.
    /// - Parameter label: The label of the navigation button.
    init(_ target: Target.Type, @ViewBuilder label: @escaping () -> Label) where Label: View {
        self.targetType = target
        self.label = label
        self.onCompletion = {}
    }
    
    /// Create a button for performing navigation actions.
    ///
    /// - Parameter target: The type of the target view for navigation.
    /// - Parameter onCompletion: The closure performed when the destination view loaded.
    /// - Parameter label: The label of the navigation button.
    init(_ target: Target.Type, onCompletion: @escaping @MainActor () -> (), @ViewBuilder label: @escaping () -> Label) where Label: View {
        self.targetType = target
        self.label = label
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        NavigationLink(value: QANavigationTarget(target: targetType.self, onCompletion: onCompletion)) {
            self.label()
        }
        
    }
}


/// The data structure used to represent navigation targets in a navigation model.
struct QANavigationTarget: Hashable {
    /// The view type corresponding to the currently stored navigation target.
    let target: any QANavigationLeaf.Type
    let onCompletion: @MainActor () -> ()
    private let hash: String
    
    fileprivate init(target: any QANavigationLeaf.Type) {
        self.target = target
        self.hash = "\(target.self)"
        self.onCompletion = {}
    }
    
    fileprivate init(target: any QANavigationLeaf.Type, onCompletion: @escaping @MainActor () -> ()) {
        self.target = target
        self.hash = "\(target.self)"
        self.onCompletion = onCompletion
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
protocol QANavigationRoot: View {
    /// The content type about the navigation component.
    associatedtype Content: View
    init()
    /// The view component
    var content: Content { get }
    var navigationTitleColor: Color { get }
    var navigationTitleDesign: UIFontDescriptor.SystemDesign { get }
}

extension QANavigationRoot {
    var body: some View {
        NavigationStack(path: QANavigationModel.current.binding(for: \.navigationPath)) {
            content
                .navigationTitleColor(navigationTitleColor)
                .navigationLargeTitleDesign(navigationTitleDesign)
                .navigationInlineTitleDesign(navigationTitleDesign)
                .navigationDestination(for: QANavigationTarget.self) { target in
                    if target == QAInputView.NavigationTarget {
                        QAInputView()
                            .environment(QANavigationModel.current)
                            .environment(QAViewModel.current)
                            .environment(QADataManager.current)
                            .onAppear(perform: target.onCompletion)
                    }  else {
                        AnyView(
                            target.target.init()
                                .onAppear(perform: target.onCompletion)
                                .environment(QANavigationModel.current)
                                .environment(QAViewModel.current)
                                .environment(QADataManager.current)
                        )
                    }
                }
        }
    }
    
    var navigationTitleColor: Color { .dynamicBlack }
    var navigationTitleDesign: UIFontDescriptor.SystemDesign { .default }
}


/// The navigation components used in the QA navigation stack.
@MainActor
protocol QANavigationLeaf: View {
    /// The content type about the navigation component.
    associatedtype Content: View
    init()
    /// The view component.
    @ViewBuilder
    var content: Content { get }
    var navigationTitleColor: Color { get }
    var navigationTitleDesign: UIFontDescriptor.SystemDesign { get }
}

extension QANavigationLeaf {
    var body: some View {
        content
            .navigationTitleColor(navigationTitleColor)
            .navigationLargeTitleDesign(navigationTitleDesign)
            .navigationInlineTitleDesign(navigationTitleDesign)
    }
    /// The navigation target corresponding to the current navigation component.
    static var NavigationTarget: QANavigationTarget {
        QANavigationTarget.init(target: self)
    }
    
    var navigationTitleColor: Color { .dynamicBlack }
    var navigationTitleDesign: UIFontDescriptor.SystemDesign { .default }
}


