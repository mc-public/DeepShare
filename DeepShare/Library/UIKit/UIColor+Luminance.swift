//
//  UIColor+Luminance.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/11.
//

import UIKit

extension UIColor {
    var luminance: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
}
