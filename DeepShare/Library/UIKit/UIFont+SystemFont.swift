//
//  UIFont+SystemFont.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import UIKit

extension UIFontDescriptor {
    func withWeight(_ weight: UIFont.Weight) -> UIFontDescriptor {
        self.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
    }
}

extension UIFont {
    static var navigationInlineTitle: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withWeight(.medium)
        return UIFont(descriptor: descriptor, size: 0.0)
    }
    
    static var navigationLargeTitle: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withWeight(.semibold)
        return UIFont(descriptor: descriptor, size: 0.0)
    }
}
