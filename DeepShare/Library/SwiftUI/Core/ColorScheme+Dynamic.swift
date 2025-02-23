//
//  ColorScheme+Dynamic.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import SwiftUI

extension ColorScheme {
    var dynamicBlack: Color {
        return switch self {
        case .light: .black
        case .dark: .white
        @unknown default:
#if DEBUG
            fatalError()
#else
            .blue
#endif
        }
    }
    
    var dynamicWhite: Color {
        return switch self {
            case .light: .white
            case .dark: .black
            @unknown default:
#if DEBUG
            fatalError()
#else
            .blue
#endif
        }
    }
   
}
