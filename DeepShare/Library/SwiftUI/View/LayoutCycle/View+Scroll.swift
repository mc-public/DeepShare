//
//  View+Scroll.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/10.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
    
    /// Set the scrollbar style of the scrollable container.
    ///
    /// - Parameter style: The scroll bar style you want to set.
    func scrollIndicatorsStyle(_ style: UIScrollView.IndicatorStyle) -> some View {
        self.introspect(.scrollView, on: .iOS(.v17...), customize: { scrollView in
            scrollView.indicatorStyle = .black
        })
    }
    
    /// Set the background color of a scrollable container.
    ///
    /// - Parameter color: The background color of the container.
    func scrollBackgroundColor(_ color: Color) -> some View {
        self.introspect(.scrollView, on: .iOS(.v17...), customize: { scrollView in
            if UIColor(color).luminance > 0.5 {
                scrollView.indicatorStyle = .black
            } else {
                scrollView.indicatorStyle = .white
            }
        })
        .background(color, ignoresSafeAreaEdges: .all)
    }
    
    /// Add color to the top or bottom edge of the `ScrollView`'s scroll container.
    ///
    /// - Parameter edges: The edges to be added.
    /// - Parameter color: The edge color which will add to edge.
    func scrollEdgeColor(_ edges: VerticalEdge..., color: Color) -> some View {
        self.introspect(.scrollView, on: .iOS(.v17...)) { scrollView in
            var isFound1 = false
            var isFound2 = false
            for case let edgeView as ScrollTopEdgeColorView in scrollView.subviews {
                if !edges.contains(.top) {
                    edgeView.removeFromSuperview()
                } else {
                    edgeView.backgroundColor = UIColor(color)
                    isFound1 = true
                }
            }
            for case let edgeView as ScrollBottomEdgeColorView in scrollView.subviews {
                edgeView.backgroundColor = UIColor(color)
                if !edges.contains(.bottom) {
                    edgeView.removeFromSuperview()
                } else {
                    edgeView.backgroundColor = UIColor(color)
                    isFound2 = true
                }
            }
            if !isFound1 && edges.contains(.top) {
                let view = ScrollTopEdgeColorView()
                view.backgroundColor = UIColor(color)
                view.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(view)
                view.widthAnchor.constraint(lessThanOrEqualTo: scrollView.widthAnchor).isActive = true
                view.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor).isActive = true
                view.heightAnchor.constraint(equalToConstant: 1001).isActive = true
                view.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
                view.topAnchor.constraint(lessThanOrEqualTo: scrollView.topAnchor, constant: -1000).isActive = true
                view.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: -1000).isActive = true
                view.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            }
            if !isFound2 && edges.contains(.bottom) {
                let view2 = ScrollBottomEdgeColorView()
                view2.backgroundColor = UIColor(color)
                view2.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(view2)
                scrollView.unsafe_temporaryProperty = scrollView.publisher(for: \.contentSize).sink { [weak scrollView] output in
                    view2.frame.origin.x = 0.0
                    view2.frame.origin.y = output.height
                    view2.frame.size.width = scrollView?.bounds.width ?? 0.0
                    view2.frame.size.height = scrollView?.bounds.height ?? 0.0
                }
            }
        }
    }
}

fileprivate class ScrollTopEdgeColorView: UIView {}
fileprivate class ScrollBottomEdgeColorView: UIView {}

nonisolated(unsafe) private var unsafe_associatedKey: UInt8 = 0
nonisolated(unsafe) private var unsafe_associatedKeyLock = NSLock()

extension UIScrollView {
    fileprivate var unsafe_temporaryProperty: Any? {
        get {
            unsafe_associatedKeyLock.withLock {
                objc_getAssociatedObject(self, &unsafe_associatedKey)
            }
        }
        set {
            unsafe_associatedKeyLock.withLock {
                objc_setAssociatedObject(self, &unsafe_associatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
