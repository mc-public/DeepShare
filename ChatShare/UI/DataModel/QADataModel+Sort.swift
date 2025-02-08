//
//  QADataModel+Sort.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/8.
//

import Localization
import Foundation

extension QADataManager {
    typealias DateSort = Sort.DateSort
    
    enum Sort: CaseIterable, Identifiable, Hashable {
        static var allCases: [QADataManager.Sort] {
            [.title] + DateSort.allCases.map({ Sort.date($0) })
        }
        
        case title
        case date(_ by: DateSort)
        
        var id: Self { self }
        var title: String {
            switch self {
                case .title: #localized("Title")
                case .date(let by): by.title
            }
        }
        
        enum DateSort: CaseIterable, Identifiable, Hashable {
            case edited
            case created
            var id: Self { self }
            var title: String {
                switch self {
                    case .edited: #localized("Date Edited")
                    case .created: #localized("Date Created")
                }
            }
        }
        
        func orderTitle(_ order: SortOrder) -> String {
            switch self {
                case .title: order == .forward ?  #localized("Ascending") : #localized("Descending")
                case .date:
                    order == .forward ? #localized("Newest First") : #localized("Oldest First")
            }
        }
    }
    
}
