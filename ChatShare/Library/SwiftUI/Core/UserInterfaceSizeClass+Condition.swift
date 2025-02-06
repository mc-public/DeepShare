//
//  UserInterfaceSizeClass+Condition.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/10.
//

import SwiftUI

extension UserInterfaceSizeClass {
    var isRegular: Bool {
        self == .regular
    }
    
    var isCompact: Bool {
        self == .compact
    }
}

extension Optional where Wrapped == UserInterfaceSizeClass {
    var isRegular: Bool {
        self?.isRegular ?? false
    }
    var isCompact: Bool {
        self?.isCompact ?? true
    }
}
