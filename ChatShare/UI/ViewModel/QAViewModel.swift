//
//  MainViewModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import Observation
import SwiftUI
import UIKit

/// The shared singleton view model about current application.
@MainActor @Observable
final class QAViewModel {
    /// The shared view model about current application.
    static let current = QAViewModel()
    private init() {}
    
#if true
    var questionContent = "Test Question Content"
    var answerContent: String = {
        let url = Bundle.main.url(forResource: "test", withExtension: "md")!
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }()
#else
    var questionContent = ""
    var answerContent = ""
#endif
    
    var isContentEmpty: Bool {
        questionContent.isEmpty || answerContent.isEmpty
    }
    
    var selectedChatAI = QAChatAIModel.deepseek_R1
    
    var imageResult: UIImage?
    
    var isShowingPreviewer: Bool = false
    
}
