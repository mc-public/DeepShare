//
//  View+PDFShare.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/9.
//

import Foundation
import SwiftUI

/// A struct representing the URL of a disk file that can be shared.
struct ShareFileURL: Identifiable, Equatable, Hashable {
    let id = UUID()
    /// The file url about the item.
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init?(url: URL?) {
        guard let url else { return nil }
        self.init(url: url)
    }
}

extension View {
    
    @ViewBuilder
    func fileShareSheet(item: Binding<ShareFileURL?>) -> some View {
        self.sheet(item: item) { item in
            NavigationStack {
                FileShareSheet(url: item.url)
            }
        }
    }
}


///  A view for sharing a file.
fileprivate struct FileShareSheet: UIViewControllerRepresentable {
    /// The images to share
    private let fileURL: URL
    
    /// Create a `FileShareSheet` instance.
    init(url: URL) {
        fileURL = url
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
