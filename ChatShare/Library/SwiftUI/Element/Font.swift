//
//  Font.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI

extension Font {
    static var navigationTitle: Self {
        Font(UIFont.navigationInlineTitle as CTFont)
    }
    
    static var navigationLargeTitle: Self {
        Font(UIFont.navigationLargeTitle as CTFont)
    }
}
