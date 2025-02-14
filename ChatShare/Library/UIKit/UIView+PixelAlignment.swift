//
//  UIView+PixelAlignment.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/14.
//

import UIKit

extension UIView {
    
    public enum PixelAlign {
        case floor
        case ceil
    }
    
    @inlinable
    func pixelAligned(for value: CGFloat, alignment: PixelAlign) -> CGFloat {
        switch alignment {
            case .floor:
                floor(value * contentScaleFactor) / contentScaleFactor
            case .ceil:
                ceil(value * contentScaleFactor) / contentScaleFactor
        }
    }
    
    @inlinable
    func pixelAligned(for value: CGSize, alignment: PixelAlign) -> CGSize {
        .init(width: pixelAligned(for: value.width, alignment: alignment), height: pixelAligned(for: value.height, alignment: alignment))
    }
    
    @inlinable
    func pixelAligned(for value: CGPoint, alignment: PixelAlign) -> CGPoint {
        .init(x: pixelAligned(for: value.x, alignment: alignment), y: pixelAligned(for: value.y, alignment: alignment))
    }
    
    @inlinable
    func pixelAligned(for value: CGRect, alignment: PixelAlign) -> CGRect {
        .init(x: pixelAligned(for: value.origin.x, alignment: alignment), y: pixelAligned(for: value.origin.y, alignment: alignment), width: pixelAligned(for: value.width, alignment: alignment), height: pixelAligned(for: value.height, alignment: alignment))
    }
}
