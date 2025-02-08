//
//  View+LifeCycle.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/8.
//

import SwiftUI

extension View {
    /// Perform actions when the view is about to appear and is being treated as a `UIViewController`.
    func onWillAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(ViewLifeCycleModifier(viewWillAppear: perform))
    }
    /// Perform actions when the view did appear and is being treated as a `UIViewController`.
    func onDidAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(ViewLifeCycleModifier(viewDidAppear: perform))
    }
    /// Perform actions when the view will disappear and is being treated as a `UIViewController`.
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        modifier(ViewLifeCycleModifier.init(viewWillDisappear: perform))
    }
    /// Perform actions when the view did disappear and is being treated as a `UIViewController`.
    func onDidDisappear(_ perform: @escaping () -> Void) -> some View {
        modifier(ViewLifeCycleModifier.init(viewDidDisappear: perform))
    }
}

fileprivate struct ViewLifeCycleModifier: ViewModifier {
    var viewWillAppear: (() -> Void)?
    var viewDidAppear: (() -> Void)?
    var viewWillDisappear: (() -> Void)?
    var viewDidDisappear: (() -> Void)?
    
    func body(content: Content) -> some View {
        content.background(UIViewControllerResponder(viewWillAppear: viewWillAppear, viewDidAppear: viewDidAppear, viewWillDisappear: viewWillDisappear, viewDidDisappear: viewDidDisappear))
    }
}

fileprivate struct UIViewControllerResponder: UIViewControllerRepresentable {

    var viewWillAppear: (() -> Void)?
    var viewDidAppear: (() -> Void)?
    var viewWillDisappear: (() -> Void)?
    var viewDidDisappear: (() -> Void)?
    
    private let controller = ViewController()

    func makeUIViewController(context: UIViewControllerRepresentableContext<UIViewControllerResponder>) -> UIViewController {
        if let viewWillAppear {
            controller.viewWillAppear = viewWillAppear
        }
        if let viewDidAppear {
            controller.viewDidAppear = viewDidAppear
        }
        if let viewWillDisappear {
            controller.viewWillDisappear = viewWillDisappear
        }
        if let viewDidDisappear {
            controller.viewDidDisappear = viewDidDisappear
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<UIViewControllerResponder>) {
    }


    /// An object that manages a view hierarchy for your UIKit app.
    private class ViewController: UIViewController {
        var viewWillAppear: () -> Void = {}
        var viewDidAppear: () -> Void = {}
        var viewWillDisappear: () -> Void = {}
        var viewDidDisappear: () -> Void = {}
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            viewWillAppear()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            viewDidAppear()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            viewWillDisappear()
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            viewDidDisappear()
        }
    }
}
