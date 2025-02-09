//
//  View+Layout.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/10.
//

import SwiftUI

extension View {
    
    /// Adds an action to be performed when a value, created from a
    /// geometry proxy, changes.
    ///
    /// The geometry of a view can change frequently, especially if
    /// the view is contained within a ``ScrollView`` and that scroll view
    /// is scrolling.
    ///
    /// - Parameters:
    ///   - body: A closure to run when the geometry size data changes.
    @available(iOS 17.0, *)
    public nonisolated func onGeometryChange(body: @escaping (_ size: CGSize) -> ()) -> some View {
        self.onGeometryChange(for: CGSize.self, of: { $0.size }, action: body)
    }
    
    /// Perform the corresponding actions.
    ///
    /// - Parameter body: A specific closure for executing the view.
    /// - Warning: The modified view will be forcibly redrawn when the view layer changes.
    public func withCondition(@ViewBuilder body: @escaping (_ view: Self) -> some View) -> some View {
        self.modifier(ConditionModifier { body(self) })
    }
    
    /// Perform the corresponding actions based on the specific `EnvironmentKey` of the current view.
    ///
    /// - Parameter key: The `KeyPath<EnvironmentValues, T>` about the environment value.
    /// - Parameter body: A specific closure for executing the view. The first parameter is the original view instance, and the second parameter is the environment value.
    public func withEnvironmentCondition<T>(key: KeyPath<EnvironmentValues, T>, @ViewBuilder body: @escaping (_ view: Self, _ value: T) -> some View) -> some View {
        self.modifier(EnvironmentConditionModified(key) { body(self, $0) })
    }
    
    /// Perform the corresponding actions based on the horizontal size category of the current view.
    ///
    /// - Parameter body: A specific closure for executing the view. The first parameter is the original view instance, and the second parameter indicates whether it is currently in the `Regular` size class.
    /// - Warning: The modified view will be forcibly redrawn when the horizontal size changes, losing the unique identifier of the SwiftUI view.
    public func withHorizontalCondition(@ViewBuilder body: @escaping (_ view: Self, _ isRegular: Bool) -> some View) -> some View {
        self.modifier(HorizontalStyleModifier { body(self, $0) })
    }
    
    /// Adds an equal padding amount to specific edges of this view.
    ///
    /// This method will not result in the loss of the view identifier.
    ///
    /// - Parameter edges: The set of edges to pad for this view. Excessive directions passed in will be ignored; for example, if both Horizontal and Leading are passed in, the padding in the Leading direction will only take effect once.
    /// - Parameter compactLength: An amount, given in points, to pad this view on the specified edges in compact size class. If you set the value to `nil`, SwiftUI uses a platform-specific default amount. The default value of this parameter is `nil`.
    /// - Parameter regularLength: An amount, given in points, to pad this view on the specified edges in regular size class. If you set the value to `nil`, SwiftUI uses a platform-specific default amount. The default value of this parameter is `nil`.
    ///
    /// - Returns: A view that’s padded by the specified amount on the specified edges.
    public func padding(_ edges: Edge.Set..., compact compactLength: CGFloat?, regular regularLength: CGFloat?) -> some View {
        let edge = edges.reduce(edges[0]) { partialResult, newEdge in
            partialResult.union(newEdge)
        }
        return self.modifier(HorizontalPaddingModified(compact: compactLength, regular: regularLength, edge: edge))
    }
    
    /// Adds an equal padding amount to specific edges of this view.
    ///
    /// This method will not result in the loss of the view identifier.
    ///
    /// - Parameter edges: The set of edges to pad for this view. Excessive directions passed in will be ignored; for example, if both Horizontal and Leading are passed in, the padding in the Leading direction will only take effect once.
    /// - Parameter length: An amount, given in points, to pad this view on the specified edges. If you set the value to `nil`, SwiftUI uses a platform-specific default amount. The default value of this parameter is `nil`.
    public func padding(_ edges: Edge.Set..., length: CGFloat? = nil) -> some View {
        let edge = edges.reduce(edges[0]) { partialResult, newEdge in
            partialResult.union(newEdge)
        }
        return self.padding(edge, length)
    }
    
    /// Insert the content of a certain view at the bottom of the current view in the form of a `VStack` with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This
    ///     guide has the same vertical screen coordinate for every subview.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the stack to choose a default distance for each pair of
    ///     subviews.
    ///   - content: A view builder that creates the content of this stack.
    public func bottomAreaInset(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            self
            content()
        }
    }
    
    /// Insert the content of a certain view at the top of the current view in the form of a `VStack` with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This
    ///     guide has the same vertical screen coordinate for every subview.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the stack to choose a default distance for each pair of
    ///     subviews.
    ///   - content: A view builder that creates the content of this stack.
    public func topAreaInset(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
            self
        }
    }
    
    /// Add a rounded corner border to the view.
    ///
    /// - Parameter radius: The radius about the border.
    /// - Parameter border: The style about the border.
    /// - Parameter borderWidth: The width of the border.
    @ViewBuilder
    public func withCornerBorder<S: ShapeStyle>(radius: CGFloat, border: S, borderWidth: CGFloat) -> some View {
        self
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(border, lineWidth: borderWidth)
            }
    }
    
    /// Add a rounded background to the view.
    ///
    /// - Parameter radius: The radius about the background.
    /// - Parameter style: The style of the background.
    @ViewBuilder
    public func withCornerBackground<S: ShapeStyle>(radius: CGFloat, style: S) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(style)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
    
    /// Hides view conditionally.
    ///
    /// - Parameter isHidden: Indicates whether to hide the current view. Hiding this view will not change its frame size.
    /// - Parameter usingRedraw: Whether to rebuild the view when hiding or recovering. Default is `false`.
    @ViewBuilder
    public nonisolated func hidden(_ isHidden: Bool, usingRedraw: Bool = false) -> some View {
        if usingRedraw {
            if isHidden {
                self.hidden()
            } else {
                self
            }
        } else {
            self.opacity(isHidden ? 0 : 1)
        }
        
    }
}


fileprivate struct HorizontalStyleModifier<T: View>: ViewModifier {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let condition: (_ isRegular: Bool) -> T
    
    func body(content: Content) -> some View {
        condition(horizontalSizeClass.isCompact)
    }
}

fileprivate struct ConditionModifier<T: View>: ViewModifier {
    
    var condition: () -> T
    
    func body(content: Content) -> some View {
        condition()
    }
}

fileprivate struct EnvironmentConditionModified<T: View, V>: ViewModifier {
    
    typealias Key = KeyPath<EnvironmentValues, V>
    let value: Environment<V>
    let condition: (_ value: V) -> T
    
    init(_ key: Key, condition: @escaping (V) -> T) {
        self.value = Environment(key)
        self.condition = condition
    }
    func body(content: Content) -> some View {
        condition(value.wrappedValue)
    }
}


fileprivate struct HorizontalPaddingModified: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var compact: CGFloat?
    var regular: CGFloat?
    var edge: Edge.Set
    
    func body(content: Content) -> some View {
        content.padding(edge, self.horizontalSizeClass.isCompact ? compact : regular)
    }
}
