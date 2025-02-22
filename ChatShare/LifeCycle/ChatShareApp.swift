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
    @State var isResourcesFailured = false
    var body: some Scene {
        WindowGroup {
            QANavigationView()
                .background {
                    DownTeX.placeHolder
                        .ignoresSafeArea(.all, edges: .all)
                }
                .task {
                    if DownTeX.current.state == .initFailed {
                        isResourcesFailured = true
                    }
                }
                .alert("Resource Decompression Failed", isPresented: $isResourcesFailured) {
                    Button("OK") {
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                        Task { @MainActor in
                            fatalError("[\(ChatShareApp.Name)] Application Killed.")
                        }
                    }
                } message: {
                    Text("Please check if the current device has enough storage space.")
                }
        }
    }
}
