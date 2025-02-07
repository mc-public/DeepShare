//
//  QAModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/6.
//

import Foundation

/// The question-answer model of current project.
struct QADataModel: Codable, Identifiable, Hashable {
    
    typealias QAID = UUID
    let id: QAID
    
    var question: String
    var answer: String
    let createDate: Date
    fileprivate(set) var modifiedDate: Date
    
    init(question: String, answer: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.modifiedDate = .now
        self.createDate = .now
    }
}

@MainActor
class QAManager {
    typealias QAID = UUID
    @MainActor
    static let current = QAManager()
    
    /// All question-answer models managed by current `QAManager`.
    var allModels: [QADataModel] = []
    
    /// Notification sent when model data changes.
    ///
    /// You can update the UI by subscribing to this notification.
    static let ProjectListDidChange = Notification.Name("\(QAManager.self).ProjectListDidChange")
    
    static private let dataBaseKey = "QADataKey"
    
    private init() {
        self.loadModels()
    }
    
    private func loadModels() {
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
    
    func add(question: String, answer: String) -> QADataModel {
        let model = QADataModel(question: question, answer: answer)
        self.allModels.append(model)
        self.saveModels()
        return model
    }
    
    func remove(id: QAID) {
        self.allModels.removeAll(\.id, id)
        self.saveModels()
    }
    
    func update(id: QAID, body: (inout QADataModel) -> Void) {
        guard let index = self.allModels.firstIndex(\.id, id) else {
            assertionFailure("[\(Self.self)][\(#function)] Trying to delete a `deleted` or `undefined` model.")
            return
        }
        body(&self.allModels[index])
        self.allModels[index].modifiedDate = .now
        self.saveModels()
        self.postChange()
    }
    
}
