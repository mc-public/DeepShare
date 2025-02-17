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
                .task {
                    do {
                        try await DownTeX.current.convertToLaTeX(markdownString: "你好世界")
                    } catch {
                        print(error)
                    }
                }
        }
    }
}
