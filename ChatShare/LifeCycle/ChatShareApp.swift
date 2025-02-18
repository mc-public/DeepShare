//
//  ChatShareApp.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import FPSMonitorLabel

@main
struct ChatShareApp: App {
    static nonisolated let Name = "ChatShare"
    var body: some Scene {
        WindowGroup {
            QANavigationView()
                .background {
                    DownTeX.placeHolder
                        .ignoresSafeArea(.all, edges: .all)
                }
                .onAppear {
//                    Task {
//                        _ = DownTeX.current
//                        for model in QADataManager.current.allModels {
//                            let data = try? await DownTeX.current.convertToPDFData(markdown: model.answer, template: QATemplateManager.current.defaultTemplate, config: .init(fontSize: .pt14, preferredPageSize: .init(width: 375, height: 500), preferredLayoutRect: .init(x: 0, y: 0, width: 375, height: 500)))
//                            if let data {
//                                FileManager.default.createFile(atPath: URL.documentsDirectory.appendingPathComponent(model.question.sanitizedFileName(), conformingTo: .pdf).path(percentEncoded: false), contents: data)
//                            }
//                            
//                        }
//                    }
                }
        }
    }
}
