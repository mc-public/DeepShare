//
//  View+Notification.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import SwiftUI

extension View {
    
    /// Execute a closure when a notification is received from `NotificationCenter.default`.
    /// - Parameter notificationName: The name of the notification to receive, which must be registered in the notification center.
    /// - Parameter action: The action to be performed upon receiving the notification, which will be executed on the main thread. The closure's parameter is the object carried by the received notification.
    ///
    /// The closure will be executed on the main thread after the notification is received.
    func onReceive( _ notificationName: Notification.Name, perform action: @escaping @MainActor (NotificationCenter.Publisher.Output) -> Void) -> some View {
        self
            .onReceive(notificationName.defaultPublisher) { output in
                MainActor.assign {
                    action(output)
                }
            }
    }
    
    
    /// Execute a closure when a notification is received from `NotificationCenter.default`.
    /// - Parameter notificationName: The name of the notification to receive, which must be registered in the notification center.
    /// - Parameter action: The action to be performed upon receiving the notification, which will be executed on the main thread.
    ///
    /// The closure will be executed on the main thread after the notification is received.
    func onReceive( _ notificationName: Notification.Name, perform action: @escaping @MainActor () -> Void) -> some View {
        self
            .onReceive(notificationName.defaultPublisher) { _ in
                MainActor.assign {
                    action()
                }
            }
    }
}


extension Notification.Name {
    fileprivate var defaultPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: self)
    }
}
