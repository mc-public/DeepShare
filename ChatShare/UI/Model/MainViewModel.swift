//
//  MainViewModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import Observation
import UIKit

@MainActor @Observable
class MainViewModel {
    
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
    var chatModel = ChatModel.deepseek_R1
    var imageResult: UIImage?
    var isShowingPreviewer: Bool = false
    
}
