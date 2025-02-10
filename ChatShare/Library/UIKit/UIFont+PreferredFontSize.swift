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
    
    static func preferredFont(relativeMetric rm: CGFloat, forTextStyle textStyle: TextStyle) -> UIFont {
        let descriptor = UIFont.preferredFont(forTextStyle: textStyle).fontDescriptor
        let standardSize = preferredFontSize(forTextStyle: textStyle)
        return UIFont(descriptor: descriptor, size: (rm / preferredFontSize(forTextStyle: .body)) * standardSize)
    }
}
