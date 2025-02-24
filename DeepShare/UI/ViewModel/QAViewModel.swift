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
    
    
    //MARK: - QAListView
    
    var listSearchText = String()
    
    var isListSearching = false
    
    var listSearchingResult: [QADataModel] {
        QADataManager.current
            .models(sort: listSort, order: listSordOrder)
            .filter(prompt: listSearchText)
    }
    
    var listSort: QADataManager.Sort = .date(.created)
    var listSordOrder: SortOrder = .forward
    var listSelectedModels = Set<QADataModel>()
    
    //MARK: - Data Share
    
    var isPasteboardHasContent = false
    var isShowingMarkdownImporter = false
    
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
        didSet {
            saveQAModel()
        }
    }
    /// The content about the QA-answer.
    var answerContent = String() {
        didSet {
            saveQAModel()
        }
    }
    
    var selectedChatAI = QAChatAIModel.deepseek_R1 {
        didSet { saveQAModel() }
    }

    var isContentEmpty: Bool { questionContent.isEmpty && answerContent.isEmpty }
    
    func clearContent() {
        self.answerContent = .init()
        self.questionContent = .init()
    }
    
    func normalizedQAMarkdownContent() -> String {
        let normalizedTitle = questionContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAnswer = answerContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let markdownContent = (normalizedTitle.isEmpty ? String() : "# ") + normalizedTitle + (normalizedAnswer.isEmpty ? String() : ("\n\n" + normalizedAnswer))
        return markdownContent
    }
    
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
                isSettingDataModelID = true
                self.selectDataModelID = nil
                isSettingDataModelID = false
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
    
    func loadMarkdownContent(url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            url.stopAccessingSecurityScopedResource()
            throw CocoaError(.fileReadNoPermission)
        }
        let data = try Data(contentsOf: url)
        let string = try NSString.createFromData(data).content
        self.loadMarkdownContentToQA(string as String)
    }
    
    func pasteFullContent() async {
        let content = UIPasteboard.general.string ?? ""
        loadMarkdownContentToQA(content)
    }
    
    private func loadMarkdownContentToQA(_ content: String) {
        let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let first = String(parts.first ?? "").trimmingPrefix(while: { $0 == "#" })
        let second = parts.count > 1 ? String(parts[1]) : ""
        self.questionContent = String(first)
        self.answerContent = second
    }
    
    //MARK: - Page Sheets
    var isShowingSinglePageSheet = false
    var isShowingSplitedPageSheet = false
    var isShowingTextConvertSheet = false
    var docxConvertResultURL: URL?
    
    //MARK: - QARenderingOptions
    var selectedTemplate: QATemplateModel = QATemplateManager.current.defaultTemplate
    var usingWaterMark = true
    var usingTitleBorder = false
    var isShowingShareFailuredAlert = false
    var horizontalPagePadding: CGFloat = 0.0
    var verticalPagePadding: CGFloat = 10.0
    var pdfResult: ShareFileURL?
    var imageResult: ShareFileURL?
    var pageRotation: QAPageRotation = .rotation4To3
    var allowTextOverflow = true
    var preventTextOverflow: Bool {
        get { !allowTextOverflow }
        set { allowTextOverflow = !newValue }
    }
    
    func cleanRenderingOptions() {
        selectedTemplate = QATemplateManager.current.defaultTemplate
        horizontalPagePadding = 0.0
        verticalPagePadding = 10.0
    }
    
    func updateSuggestedPagePadding(pageWidth: CGFloat) {
        let size = CGSize(width: pageWidth, height: pageWidth)
        if let pageLayout = QATemplateManager.current.pageRects(for: selectedTemplate, preferredSize: size) {
            let paddingLeft = max(0, pageLayout.suggestedRect.minX - pageLayout.suggestedRect.minX)
            let paddingRight = max(0, pageLayout.layoutRect.maxX - pageLayout.suggestedRect.maxX)
            let paddingTop = max(0, pageLayout.suggestedRect.minY - pageLayout.layoutRect.minY)
            let paddingBottom = max(0, pageLayout.layoutRect.maxY - pageLayout.suggestedRect.maxY)
            verticalPagePadding = max(paddingTop, paddingBottom)
            horizontalPagePadding = max(paddingLeft, paddingRight)
        }
    }
    
    @objc @MainActor
    func contentDidChangeInPasteboard() {
        isPasteboardHasContent = UIPasteboard.general.hasStrings
    }
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChangeInPasteboard), name: UIPasteboard.changedNotification, object: nil)
        self.contentDidChangeInPasteboard()
    }
}
