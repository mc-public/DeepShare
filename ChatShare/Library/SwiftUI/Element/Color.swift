//
//  Color.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/5.
//

import SwiftUI

extension Color {
    
    /// The default cell color of `List`.
    static let listBackgroundColor = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? UIColor(red: 0.949, green: 0.949, blue: 0.976, alpha: 1.0) : UIColor(red: 0.110, green: 0.102, blue: 0.118, alpha: 1.0)
        }
        return Color(uiColor)
    }()
    
    /// The default background color of `List`.
    static let listCellBackgroundColor = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? UIColor.white : UIColor(red: 0.161, green: 0.153, blue: 0.169, alpha: 1.0)
        }
        return Color(uiColor)
    }()
    
    /// The deep orange.
    static let deepOrange = Color(red: 0.886, green: 0.659, blue: 0.063)
    
    /// The dynamic white.
    static let dynamicWhite = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? .white : .black
        }
        return Color(uiColor)
    }()
    
    /// The dynamic white.
    static let dynamicBlack = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? .black: .white
        }
        return Color(uiColor)
    }()
    
    /// Create a dual color that respects the color mode.
    ///
    /// - Parameter light: The color showing in the light mode.
    /// - Parameter light: The color showing in the dark mode.
    init(light: Color, dark: Color) {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? UIColor(light) : UIColor(dark)
        }
        self.init(uiColor)
    }
}
