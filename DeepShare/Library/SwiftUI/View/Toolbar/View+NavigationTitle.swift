//
//  View+NavigationTitle.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    
    /// Set the color of the navigation title.
    ///
    /// - Parameter color: The color of the navigation title.
    /// - Warning: Please pass in an immutable constant. Modifying this value will not cause the view to update.
    /// - Warning: The `.toolbarBackground(_:for:)` and `toolbarBackgroundVisibility(_:for:)` modifiers will affect the normal operation of this modifier and lead to undefined behavior.
    @ViewBuilder
    public func navigationTitleColor(_ color: Color?) -> some View {
        let changeColor = { (viewController: UINavigationController) -> Void in
            if viewController.navigationBar.titleTextAttributes == nil {
                viewController.navigationBar.titleTextAttributes = [:]
            }
            if viewController.navigationBar.largeTitleTextAttributes == nil {
                viewController.navigationBar.largeTitleTextAttributes = [:]
            }
            viewController.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor(color ?? .dynamicBlack)
            viewController.navigationBar.largeTitleTextAttributes?[.foregroundColor] = UIColor(color ?? .dynamicBlack)
        }
        self.modifier(NavigationControllerModifier(trigger: color, process: changeColor))
            .introspect(.navigationStack, on: .iOS(.v17...), customize: changeColor)
            
    }
    
    /// Set the font design style for the large title of the navigation title.
    ///
    /// - Parameter design: The font design style for the navigation large title.
    /// - Warning: Please pass in an immutable constant. Modifying this value will not cause the view to update.
    /// - Warning: The `.toolbarBackground(_:for:)` and `toolbarBackgroundVisibility(_:for:)` modifiers will affect the normal operation of this modifier and lead to undefined behavior.
    @ViewBuilder
    public func navigationLargeTitleDesign(_ design: UIFontDescriptor.SystemDesign) -> some View {
        let changeDesign = { (viewController: UINavigationController) -> Void in
            if viewController.navigationBar.largeTitleTextAttributes == nil {
                viewController.navigationBar.largeTitleTextAttributes = [:]
            }
            if let font = viewController.navigationBar.largeTitleTextAttributes?[.font] as? UIFont, let descriptor = font.fontDescriptor.withDesign(design) {
                viewController.navigationBar.largeTitleTextAttributes?[.font] =  UIFont(descriptor: descriptor, size: font.pointSize)
            } else {
                guard let descriptor = UIFont.navigationLargeTitle.fontDescriptor.withDesign(design) else {
                    return
                }
                viewController.navigationBar.largeTitleTextAttributes?[.font] = UIFont(descriptor: descriptor, size: 0.0)
            }
        }
        self.modifier(NavigationControllerModifier(trigger: design, process: changeDesign))
    }
    
    /// Set the font design style for the inline title of the navigation title.
    ///
    /// - Parameter design: The font design style for the inline title.
    /// - Warning: Please pass in an immutable constant. Modifying this value will not cause the view to update.
    /// - Warning: The `.toolbarBackground(_:for:)` and `toolbarBackgroundVisibility(_:for:)` modifiers will affect the normal operation of this modifier and lead to undefined behavior.
    @ViewBuilder
    public func navigationInlineTitleDesign(_ design: UIFontDescriptor.SystemDesign) -> some View {
        let changeDesign = { (viewController: UINavigationController) -> Void in
            if viewController.navigationBar.titleTextAttributes == nil {
                viewController.navigationBar.titleTextAttributes = [:]
            }
            if let font = viewController.navigationBar.titleTextAttributes?[.font] as? UIFont, let descriptor = font.fontDescriptor.withDesign(design) {
                viewController.navigationBar.titleTextAttributes?[.font] =  UIFont(descriptor: descriptor, size: font.pointSize)
            } else {
                guard let descriptor = UIFont.navigationInlineTitle.fontDescriptor.withDesign(design) else {
                    return
                }
                viewController.navigationBar.titleTextAttributes?[.font] = UIFont(descriptor: descriptor, size: 0.0)
            }
        }
        self.modifier(NavigationControllerModifier(trigger: design, process: changeDesign))
    }
}


fileprivate struct NavigationControllerModifier<Trigger: Equatable>: ViewModifier {
    fileprivate class ModifierModel: ObservableObject {
        weak var viewController: UINavigationController?
    }
    let process: (UINavigationController) -> ()
    let trigger: Trigger
    @StateObject var state = ModifierModel()
    
    init(trigger: Trigger, process: @escaping (UINavigationController) -> Void) {
        self.trigger = trigger
        self.process = process
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger, initial: true, { _, _ in
                performAction()
            })
            .onAppear(perform: performAction)
            .onWillAppear(performAction)
            .onDidAppear(performAction)
            .onWillDisappear(performAction)
            .introspect(.navigationStack, on: .iOS(.v17...), scope: .ancestor) { viewController in
                if self.state.viewController == nil {
                    self.state.viewController = viewController
                    self.process(viewController)
                }
            }
    }
    
    func performAction() {
        if let viewController = state.viewController {
            self.process(viewController)
        }
    }
}

