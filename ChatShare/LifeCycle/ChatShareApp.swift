//
//  ChatShareApp.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

import SwiftUI
import FPSMonitorLabel

struct EqualStorage<Value>: Equatable {
    static func == (lhs: EqualStorage<Value>, rhs: EqualStorage<Value>) -> Bool {
        true
    }
    
    let value: Value
}

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
                    _ = DownTeX.current
                }
                .onAppear {
                    
                }
        }
    }
}
