//
//  UIViewController+StatusBarHeight.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/12.
//

import UIKit

fileprivate let defaultStatusBarHeight: CGFloat = 20

extension UIViewController {
    /// Get the height of the status-bar about current `UIViewController`.
    var statusBarHeight: CGFloat {
        self.view?.statusBarHeight ?? defaultStatusBarHeight
    }
}


extension UIView {
    /// Get the height of the status-bar about current `UIView`.
    var statusBarHeight: CGFloat {
        window?.windowScene?.statusBarManager?.statusBarFrame.height ?? defaultStatusBarHeight
    }
}
