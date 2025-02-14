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
//#if DEBUG
//                .overlay(alignment: .top) {
//                    FPSMonitorLabel()
//                }
//#endif
        }
    }
}
