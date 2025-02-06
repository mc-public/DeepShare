//
//  View+Persistent.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    
    /// Force a redraw of the view at important lifecycle nodes of the view.
    ///
    /// Commonly used to solve layout issues caused by the unexpected disappearance of some views.
    ///
    /// - Parameter isActive: Whether to activate the redraw function. Default is true.
    @ViewBuilder @MainActor
    public func itemRedrawable(_ isActive: Bool = true) -> some View {
        if !isActive { self } else { self.modifier(ViewPersistent()) }
    }
    
    /// Remove the sidebar toggle button present by `NavigationSplitView`.
    ///
    /// Usage:
    /// ```swift
    /// NavigationSplitView {
    ///     ///...
    /// } detail: {
    ///     ///...
    /// }
    /// .navigationSplitViewHideSidebarToggle()
    /// ```
    @ViewBuilder
    public func navigationSplitViewHideSidebarToggle() -> some View {
        let modifier = SplitViewModifier { splitController in
            splitController.displayModeButtonVisibility = .never
            splitController.presentsWithGesture = false
        } onDisappear: { splitController in
            splitController.displayModeButtonVisibility = .never
            splitController.presentsWithGesture = false
        }
        self.modifier(modifier)
    }
    
    /// Specifies the non-visibility of a bar managed by SwiftUI.
    @ViewBuilder
    public nonisolated func toolbarHidden(_ bar: ToolbarPlacement) -> some View {
        if #available(iOS 18, *) {
            self.toolbarVisibility(.hidden, for: bar)
                .toolbar(removing: .sidebarToggle)
        } else {
            self.toolbar(.hidden, for: bar)
                .toolbar(removing: .sidebarToggle)
        }
    }
}


fileprivate struct ViewPersistent: ViewModifier {
    @State private var id = UUID()
    @State var isActive: Bool = true
    func body(content: Content) -> some View {
        content
            .id(self.id)
            .onGeometryChange(body: { _ in
                self.id = UUID()
            })
            .onDisappear {
                self.id = UUID()
            }
            .onReceive(UIApplication.willEnterForegroundNotification) {
                self.id = UUID()
            }
            .onReceive(UIApplication.didEnterBackgroundNotification) {
                self.id = UUID()
            }
    }
}

fileprivate class SplitViewModifierModel: ObservableObject {
    weak var viewController: UISplitViewController?
}

fileprivate struct SplitViewModifier: ViewModifier {
    let withIntrospect: (_ splitController: UISplitViewController) -> Void
    let onDisappear: (_ splitController: UISplitViewController) -> Void
    
    @StateObject private var model = SplitViewModifierModel()
    
    func body(content: Content) -> some View {
        content.introspect(.navigationSplitView, on: .iOS(.v17...)) {
            model.viewController = $0
            withIntrospect($0)
        }
        .onDisappear {
            if let viewController = model.viewController { onDisappear(viewController) }
        }
    }
}
