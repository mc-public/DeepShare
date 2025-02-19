//
//  QAPageRotation.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import Foundation

enum QAPageRotation: CaseIterable, Hashable, Identifiable {
    var id: Self { self }
    case rotation4To3
    case rotation1To1
    case rotation16To9
    
    var title: String {
        switch self {
            case .rotation4To3: "4:3"
            case .rotation1To1: "1:1"
            case .rotation16To9: "16:9"
        }
    }
    func viewSize(width: CGFloat) -> CGSize {
        switch self {
            case .rotation4To3: CGSize(width: width, height: 6.0 * width / 5.0)
            case .rotation1To1: CGSize(width: width, height: width)
            case .rotation16To9: CGSize(width: width, height: 3.0 * width / 2.0)
        }
    }
    func size(width: CGFloat) -> CGSize {
        switch self {
            case .rotation4To3: CGSize(width: width, height: 4.0 * width / 3.0)
            case .rotation1To1: CGSize(width: width, height: width)
            case .rotation16To9: CGSize(width: width, height: 16.0 * width / 9.0)
        }
    }
}
