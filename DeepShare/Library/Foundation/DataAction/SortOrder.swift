//
//  SortOrder.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/9.
//

import Foundation

extension SortOrder: @retroactive CaseIterable, @retroactive Identifiable {
    public var id: Self { self }
    
    public static var allCases: [SortOrder] {
        [SortOrder.forward, SortOrder.reverse]
    }
}
