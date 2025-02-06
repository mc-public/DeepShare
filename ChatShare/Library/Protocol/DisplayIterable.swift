//
//  DisplayIterable.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/8.
//

protocol DisplayIterable: RawRepresentable<String>, CaseIterable, Identifiable, Codable {
}

extension DisplayIterable {
    var displayName: String {
        self.rawValue
    }
    var id: String {
        self.displayName
    }
}

