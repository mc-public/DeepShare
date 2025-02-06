//
//  ImageShareView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/5.
//

import Foundation
import SwiftUI

///  A view for sharing an image. The user can add the image to their cameraroll, share it via iMessage, etc.
struct ImageShareSheet: UIViewControllerRepresentable {
    /// The images to share
    private let image: UIImage
    private let url: URL
    
    /// Create a `ImageShareSheet` instance.
    init(image: UIImage, name: String) {
        self.image = image
        self.url = URL.documentsDirectory.appending(component: UUID().uuidString).appendingPathComponent(name, conformingTo: .jpeg)
        guard let data = image.jpegData(compressionQuality: 1) else {
            return
        }
        FileManager.default.createFile(atPath: self.url.path(percentEncoded: false), contents: data)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

extension View {
    func imageShareSheet(
        item: Binding<UIImage?>,
        imageName: String
    ) -> some View {
        return sheet(item: item) { item in
            ImageShareSheet(image: item, name: imageName)
        }
    }
    
}
