//
//  Color.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/5.
//

import SwiftUI

extension Color {

    static let listBackgroundColor = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? UIColor(red: 0.949, green: 0.949, blue: 0.976, alpha: 1.0) : UIColor(red: 0.110, green: 0.102, blue: 0.118, alpha: 1.0)
        }
        return Color(uiColor)
    }()
    
    static let listCellBackgroundColor = {
        let uiColor = UIColor.init { collection in
            collection.userInterfaceStyle == .light ? UIColor.white : UIColor(red: 0.161, green: 0.153, blue: 0.169, alpha: 1.0)
        }
        return Color(uiColor)
    }()
    
    static let deepOrange = Color(red: 0.886, green: 0.659, blue: 0.063)
}
