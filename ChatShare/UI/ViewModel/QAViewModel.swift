//
//  QAViewModel.swift
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
    
    //MARK: - QAListView
    
    var listSearchText = String()
    var isListSearching = false
    var listSearchingResult: [QADataModel] {
        QADataManager.current
            .models(sort: listSort, order: listSordOrder)
            .filter(prompt: listSearchText)
    }
    var listSort: QADataManager.Sort = .date(.created)
    var listSordOrder: SortOrder = .reverse
    var listSelectedModels = Set<QADataModel>()
    
    //MARK: - Data Share
    
    private var isSettingDataModelID: Bool = false
    /// Selected data model about the `QAInputView`.
    private(set) var selectDataModelID: QADataModel.QAID? {
        didSet {
            if let selectDataModelID, let model = QADataManager.current[selectDataModelID] {
                questionContent = model.question
                answerContent = model.answer
            }
        }
    }
    
    /// The content about the QA-question.
    var questionContent = String() {
        didSet { saveQAModel() }
    }
    /// The content about the QA-answer.
    var answerContent = String() {
        didSet { saveQAModel() }
    }
    
    var selectedChatAI = QAChatAIModel.deepseek_R1 {
        didSet { saveQAModel() }
    }
    var isContentEmpty: Bool { questionContent.isEmpty && answerContent.isEmpty }
    
    func prepareForQAModel(_ model: QADataModel) {
        selectDataModelID = model.id
    }
    
    func prepareNewQAContent() {
        if isSettingDataModelID { return }
        isSettingDataModelID = true
        selectDataModelID = nil
        questionContent = .init()
        answerContent = .init()
        isSettingDataModelID = false
    }
    
    func saveQAModel() {
        if isSettingDataModelID { return }
        if let selectDataModelID { // Need to save data
            if isContentEmpty {
                QADataManager.current.remove(id: selectDataModelID)
            } else {
                QADataManager.current.update(id: selectDataModelID) { model in
                    model.answer = answerContent
                    model.question = questionContent
                }
            }
        } else {
            if isContentEmpty { return }
            isSettingDataModelID = true
            selectDataModelID = QADataManager.current.add(question: questionContent, answer: answerContent, chatAI: selectedChatAI).id
            isSettingDataModelID = false
        }
    }
    
    //MARK: - Image Result
    
    var isShowingPreviewer: Bool = false
    var pdfResult: ShareFileURL?
    var imageResult: ShareFileURL?
    
}
