//
//  UIFont+PreferredFontSize.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/10.
//

import UIKit

extension UIFont {
    static func preferredFontSize(forTextStyle textStyle: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: textStyle).pointSize
    }
}
