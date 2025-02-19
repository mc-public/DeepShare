//
//  QAPageRotation.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/19.
//

import Foundation

enum QAPageRotation {
    case rotationThreeFour
    case rotationOneOne
    func size(width: CGFloat) -> CGSize {
        switch self {
            case .rotationThreeFour: CGSize(width: width, height: width)
            case .rotationOneOne: CGSize(width: width, height: 4.0 * width / 3.0)
        }
    }
}
