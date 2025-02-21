//
//  QATextConvertView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/22.
//

import SwiftUI
import Localization
import SVProgressHUD
@_spi(Advanced) import SwiftUIIntrospect

struct QATextConvertView: View {
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var isDisabled = true
    @State var isConvertFailured = false
    @State var isShareFileFailured = false
    @State var convertResult = String()
    @State var convertFileURL: ShareFileURL?
    @State var convertFormat = DownTeX.TargetFormat.plainText
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(convertFormat.title)
                .toolbar(content: toolbarContent)
                .toolbarTitleDisplayMode(.inline)
                .toolbarTitleMenu(content: toolbarMenu)
                .disabled(isDisabled)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .onChange(of: convertFormat, initial: true) { _, newValue in
            self.convert(format: newValue)
        }
        .alert("Share Failured", isPresented: $isShareFileFailured, actions: {
            Button("OK") {}
        })
        .fileShareSheet(item: $convertFileURL)
    }
    
    @ViewBuilder
    var content: some View {
        TextEditor(text: $convertResult)
            .fontDesign(.monospaced)
            .introspect(.textEditor, on: .iOS(.v17...)) { view in
                view.isEditable = false
            }
    }
    
    @ViewBuilder
    func toolbarMenu() -> some View {
        ForEach(DownTeX.TargetFormat.allCases) { item in
            Button(item.title) {
                self.convertFormat = item
            }
        }
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Copy to Clipboard", systemImage: "document.on.document", action: copyResultToClipboard)
                Button("Share as File", systemImage: "text.document", action: shareTextAsFile)
            } label: {
                Text("Share")
            }
            .menuStyle(.button)
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.teal)
            .disabled(isDisabled)
        }
    }
    
    private func convert(format: DownTeX.TargetFormat) {
        isConvertFailured = false
        isDisabled = true
        SVProgressHUD.show()
        Task {
            defer {
                isDisabled = false
                SVProgressHUD.dismiss()
            }
            let normalizedTitle = viewModel.questionContent.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedAnswer = viewModel.answerContent.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (normalizedTitle.isEmpty ? String() : "# ") + normalizedTitle + (normalizedAnswer.isEmpty ? String() : ("\n\n" + normalizedAnswer))
            let markdownString = title + viewModel.answerContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let result = try? await DownTeX.current.convertToText(markdownString: markdownString, format: format) else {
                isConvertFailured = true
                return
            }
            isConvertFailured = false
            self.convertResult = result
        }
        
    }
    
    private func copyResultToClipboard() {
        UIPasteboard.general.string = self.convertResult
        self.isDisabled = true
        Task {
            defer { self.isDisabled = false }
            if let image = UIImage(systemName: "checkmark") {
                SVProgressHUD.show(image, status: #localized("Copied to Clipboard"))
                await SVProgressHUD.dismiss(withDelay: 1.5)
            }
        }
    }
    
    private func shareTextAsFile() {
        self.isDisabled = true
        defer { self.isDisabled = false }
        let fileName = viewModel.questionContent.sanitizedFileName(empty: #localized("Untitled"))
        guard let data = convertResult.data(using: .utf8) else {
            isShareFileFailured = true
            return
        }
        let dir = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let url = dir.appendingPathComponent(fileName + "." + convertFormat.extensionName)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: data) {
            isShareFileFailured = true
            return
        }
        self.convertFileURL = .init(url: url)
    }
}
