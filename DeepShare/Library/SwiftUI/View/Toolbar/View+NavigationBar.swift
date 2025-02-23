//
//  View+NavigationBar.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/13.
//

import SwiftUI
import Combine
@_spi(Advanced) import SwiftUIIntrospect

/// The height of the `NavigationBar` in regular class.
fileprivate var regularBarHeight: CGFloat { 50 }
/// The height of the `NavigationBar` in compact class.
fileprivate var compactBarHeight: CGFloat { 44 }

/// The state of the navigation bar.
@MainActor @Observable
public class NavigationBarState {
    /// The extra height of the bar.
    public var padding: CGFloat
    /// Indicates whether to display the bottom separator line.
    public var isShowingBottomDivider: Bool
    fileprivate var bottomAreaHeight: CGFloat = .zero
    fileprivate var statusBarHeight: CGFloat = 0
    fileprivate var scrollHeight: CGFloat = .zero
    @ObservationIgnored
    fileprivate var scrollObserverCancellable: Cancellable?
    @ObservationIgnored
    fileprivate weak var scrollView: UIScrollView? {
        didSet {
            if let oldValue, let scrollView, oldValue === scrollView { return }
            guard let scrollView else { return }
            scrollObserverCancellable = scrollView.publisher(for: \.contentOffset).sink { size in
                MainActor.assign { [weak scrollView, weak self] in
                    self?.scrollHeight = size.y + scrollView?.safeAreaInsets.top + self?.padding
                }
            }
        }
    }
    
    /// Create an instance of the `NavigationBarState`.
    ///
    /// Please use @StateObject to maintain an instance of this class, and then pass it to the corresponding API. Do not construct this class directly in the parameters about these API.
    ///
    /// - Parameter padding: Indicates whether to add avertical padding of the whole navigation bar (with the bottom area). The default value for this setting is `.zero`.
    /// - Parameter isShowingBottomDivider: Indicates whether to insert a divider line at the bottom of the navigation bar. Default is `true`.
    public init(padding: CGFloat = 0, isShowingBottomDivider: Bool = true) {
        self.padding = padding
        self.isShowingBottomDivider = isShowingBottomDivider
    }
}

extension View {
    
    /// Appending an customized navigation bar on the **top-safe area** of current view.
    ///
    /// The usage method is as follows.
    /// ```swift
    /// @State var height = CGFloat.zero
    ///
    /// NavigationStack {
    ///     List {
    ///         ForEach(0..<100) {
    ///             Text("\($0)")
    ///         }
    ///     }
    ///     .customizedNavigationBar(scrollHeight: $height) {
    ///         HStack {
    ///             Title("Title").fontWeight(.semibold)
    ///             Spacer()
    ///         }
    ///     }
    /// }
    /// ```
    /// - Warning: At this time, all APIs provided by SwiftUI for managing the NavigationBar are unavailable.
    ///
    /// - Parameter usingSafeAreaInsert: Indicates whether to insert this bar into the top safe area. The default value for this setting is `true`.
    /// - Parameter state: The state of current navigation bar.
    /// - Parameter content: The content of the navigation bar. If using the default bar height, the height of this view will fixed as `50` in regular class and `44` in compact class.
    /// - Parameter bottomAddition: An additional view inserted at the bottom of the top navigation bar. If you do not want to insert this view, please pass `nil`. The default value is `nil`.
    @MainActor public func customizedNavigationBar(usingSafeAreaInsert: Bool = true, state: Binding<NavigationBarState>, @ViewBuilder content: () -> some View, bottomAddition: (() -> (some View))? = Optional<(() -> Spacer)>.none) -> some View {
        self.customizedNavigationBar(usingSafeAreaInsert: usingSafeAreaInsert, state: state, content: content(), bottomAddition: bottomAddition?() ?? nil)
    }
    
    @ViewBuilder
    private func customizedNavigationBar(usingSafeAreaInsert: Bool, state: Binding<NavigationBarState>, content: some View, bottomAddition: (some View)?) -> some View {
        if usingSafeAreaInsert {
            self
                .toolbarHidden(.automatic)
                .safeAreaInset(edge: .top, alignment: .center, spacing: 0.0) {
                    NavigationBar(bar: content, bottom: bottomAddition, overlay: true, state: state)
                }
                .modifier(NavigationBarModifier(state: state))
        } else {
            VStackLayout(alignment: .center, spacing: 0) {
                NavigationBar(bar: content, bottom: bottomAddition, overlay: false, state: state)
                self
            }
            .toolbarHidden(.automatic)
            .ignoresSafeArea(.all, edges: .top)
        }
    }
}


fileprivate struct NavigationBarModifier: ViewModifier {
    
    @Binding var state: NavigationBarState
    
    func body(content: Content) -> some View {
        content
            .introspect(.scrollView, on: .iOS(.v17...)) { scrollView in
                state.scrollView = scrollView
                let isRegular = (scrollView.traitCollection.horizontalSizeClass == .regular)
                let barHeight = isRegular ? regularBarHeight : compactBarHeight
                scrollView.automaticallyAdjustsScrollIndicatorInsets = false
                scrollView.verticalScrollIndicatorInsets.top = barHeight + scrollView.statusBarHeight + state.padding + state.bottomAreaHeight
                Task {
                    state.scrollHeight = scrollView.contentOffset.y + scrollView.safeAreaInsets.top + state.padding
                }
            }
    }
}

fileprivate struct NavigationBar<Content, Addition>: View where Content: View, Addition: View {
    
    private let usingOverlay: Bool
    private var bar: Content
    private var bottom: Addition?
    
    @Binding var state: NavigationBarState
    
    private var barHeight: CGFloat {
        (horizontalSizeClass == .regular ? regularBarHeight : compactBarHeight)
    }
    private var bottomAreaHeight: CGFloat {
        state.bottomAreaHeight
    }
    private var statusBarHeight: CGFloat {
        state.statusBarHeight
    }
    private var isShowingDivider: Bool {
        state.isShowingBottomDivider
    }
    private var totalHeight: CGFloat {
        statusBarHeight + barHeight + state.bottomAreaHeight + state.padding
    }
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(bar: Content, bottom: Addition?, overlay: Bool, state: Binding<NavigationBarState>) {
        self.bar = bar
        self.bottom = bottom
        self.usingOverlay = overlay
        self._state = state
    }
    
    @ViewBuilder
    var bottomArea: some View {
        if let bottom {
            bottom
                .onGeometryChange { state.bottomAreaHeight = $0.height }
        }
    }
    
    var body: some View {
        if !usingOverlay {
            VStackLayout(alignment: .center, spacing: 0.0) {
                content
                bottomArea
                if state.isShowingBottomDivider {
                    divider
                }
            }
            .background(background, ignoresSafeAreaEdges: .top)
            .frame(height: totalHeight, alignment: .center)
            .introspect(.viewController, on: .iOS(.v17...)) { viewController in
                if state.statusBarHeight == .zero {
                    state.statusBarHeight = viewController.statusBarHeight
                }
            }
        } else {
            content
        }
    }
    
    static var scrollTransitionPoint: CGFloat { 20.0 }
    @ViewBuilder
    var content: some View {
        VStackLayout(alignment: .center, spacing: 0.0) {
            bar
                .frame(height: barHeight)
                .padding(.horizontal)
            if usingOverlay {
                bottomArea
                if isShowingDivider {
                    divider
                }
            }
        }
        .withCondition {
            if usingOverlay { $0.background(background, ignoresSafeAreaEdges: .top) } else { $0 }
        }
        .frame(height: usingOverlay ? barHeight + state.bottomAreaHeight + state.padding : barHeight)
    }
    
    var divider: some View {
        Divider()
            .opacity(opacityValue)
    }
    
    var background: some ShapeStyle {
        Material.bar.opacity(opacityValue)
    }
    
    var opacityValue: CGFloat {
        state.scrollHeight < Self.scrollTransitionPoint ? (state.scrollHeight / Self.scrollTransitionPoint) : 1.0
    }
}
