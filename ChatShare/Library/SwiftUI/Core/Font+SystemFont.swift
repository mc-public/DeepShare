//
//  Font+SystemFont.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/10.
//

import SwiftUI

extension Font {
    static func preferredFont(relativeMetric rm: CGFloat, style: UIFont.TextStyle) -> Self {
        self.init(UIFont.preferredFont(relativeMetric: rm, forTextStyle: style) as CTFont)
    }
}
