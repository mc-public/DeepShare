//
//  QADataModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/6.
//

import Foundation
import Localization
import SwiftUI

private let USING_TEST_DATA = true

//MARK: - Data Model

/// The question-answer model of current project.
struct QADataModel: Codable, Identifiable, Hashable, Sendable {
    
    typealias QAID = UUID
    let id: QAID
    
    var question: String
    var answer: String
    var chatAI: QAChatAIModel
    
    let createDate: Date
    var createDateType: DateType { .init(from: createDate) }
    
    fileprivate(set) var editedDate: Date
    var editedDateType: DateType { .init(from: editedDate) }
    
    init(question: String, answer: String, chatAI: QAChatAIModel) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.editedDate = .now
        self.createDate = .now
        self.chatAI = chatAI
    }
    
    init() {
        self.init(question: String(), answer: String(), chatAI: .deepseek_R1)
    }
}

extension QADataModel {
    enum DateType: Identifiable, Hashable {
        case previous7Day
        case previous30Day
        case year(_ yearNumber: Int)
        var id: Int {
            switch self {
                case .previous7Day: -2
                case .previous30Day: -1
                case .year(let value): value
            }
        }
        var title: String {
            switch self {
                case .previous7Day: #localized("Previous 7 Days")
                case .previous30Day: #localized("Previous 30 Days")
                case .year(let value): String(value)
            }
        }
        
        init(from date: Date) {
            let diffComponents = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? .max
            if diffComponents <= 7 {
                self = .previous7Day
            } else if diffComponents <= 30 {
                self = .previous30Day
            } else {
                self = .year(date.get(.year).year ?? 2024)
            }
        }
    }
}

//MARK: - Data Manager

@MainActor @Observable
class QADataManager {
    
    /// The unique-identifier about the question-answer.
    typealias QAID = QADataModel.ID
    /// The shared `QADataManager` about current application.
    @MainActor
    static let current = QADataManager()
    
    /// All question-answer models managed by current `QAManager`.
    var allModels: [QADataModel] = []
    
    var untitledCount: Int {
        self.allModels.filter(\.question, String()).count
    }

    static private let testModelData: [QADataModel] = {
        struct JSONModel: Decodable {
            let filename: String
            let question: String
        }
        let url = Bundle.main.url(forResource: "testFileDirectory", withExtension: "json")!
        let data = (try? Data(contentsOf: url)) ?? .init()
        let modelMap = (try? JSONDecoder().decode([JSONModel].self, from: data)) ?? []
        return modelMap.map { jsonModel in
            let url = Bundle.main.url(forResource: jsonModel.filename, withExtension: "")!
            let answer = (try? String(contentsOf: url, encoding: .utf8)) ?? "UNKNOWN"
            let model = QADataModel(question: jsonModel.question, answer: answer, chatAI: .deepseek_R1)
            return model
        }
    }()

    
    /// Notification sent when model data changes.
    ///
    /// You can update user interface by subscribing to this notification.
    static let ProjectListDidChange = Notification.Name("\(QADataManager.self).ProjectListDidChange")
    
    static private let dataBaseKey = "QADataKey"
    
    private init() {
        self.loadModels()
    }
    
    private func loadModels() {
        if USING_TEST_DATA {
            self.allModels = Self.testModelData
            self.saveModels()
            return
        }
        guard let data = UserDefaults.standard.data(forKey: Self.dataBaseKey) else {
            UserDefaults.standard.set(Data(), forKey: Self.dataBaseKey)
            self.allModels = []
            return
        }
        
        self.allModels = (try? JSONDecoder().decode([QADataModel].self, from: data)) ?? []
    }
    
    private func saveModels() {
        let data = try? JSONEncoder().encode(self.allModels)
        UserDefaults.standard.set(data, forKey: Self.dataBaseKey)
    }
    
    private func postChange() {
        NotificationCenter.default.post(name: Self.ProjectListDidChange, object: nil)
    }
    
    subscript(id: QAID) -> QADataModel? {
        self.allModels.filter(\.id, id).first
    }
    
    func add(question: String, answer: String, chatAI: QAChatAIModel) -> QADataModel {
        let model = QADataModel(question: question, answer: answer, chatAI: chatAI)
        self.allModels.append(model)
        self.saveModels()
        self.postChange()
        return model
    }
    
    func remove(id: QAID) {
        self.allModels.removeAll(\.id, id)
        self.saveModels()
        self.postChange()
    }
    
    func update(id: QAID, body: (inout QADataModel) -> Void) {
        guard let index = self.allModels.firstIndex(\.id, id) else {
            assertionFailure("[\(Self.self)][\(#function)] Trying to delete a `deleted` or `undefined` model.")
            return
        }
        body(&self.allModels[index])
        self.allModels[index].editedDate = .now
        self.saveModels()
        self.postChange()
    }
    
    func dateTypes(sort: DateSort, order: SortOrder, filterPrompt: String = String()) -> [QADataModel.DateType] {
        let models = self.models(sort: .date(sort), order: order)
            .filter(prompt: filterPrompt)
        return Array(Set(models.map { sort == .created ? $0.createDateType : $0.editedDateType }))
    }
    
    func models(sort: Sort, order: SortOrder) -> [QADataModel] {
        self.allModels
            .sorted { left, right in
                var result = switch sort {
                    case .title: left.question > right.answer
                    case .date(let dateSort): dateSort == .edited ? (left.editedDate > right.editedDate) : (left.createDate > right.createDate)
                }
                if order == .reverse { result.toggle() }
                return result
            }
    }
    
    func models(sort: DateSort, dateType: QADataModel.DateType, order: SortOrder) -> [QADataModel] {
        self.models(sort: .date(sort), order: order)
            .filter { model in
                dateType == (sort == .created ? model.createDateType : model.editedDateType)
            }
    }
}

extension Array where Element == QADataModel {
    func filter(prompt: String) -> [QADataModel] {
        if prompt.isEmpty { return self }
        return self.filter { model in
            model.question.contains(prompt) || model.answer.contains(prompt)
        }
    }
}
