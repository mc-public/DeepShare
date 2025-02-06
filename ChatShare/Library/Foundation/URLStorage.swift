//
//  URLStorage.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import Foundation

/// Class for providing `URL` permission access control for the entire APP.
///
/// This class can be safely accessed from any queue.
final class URLStorage: @unchecked Sendable {
    
    private static var storageKey: String {
        "\(Self.self)_Encoded_Bookmark_Data"
    }
    
    private static let share: URLStorage = .init()
    
    @AtomicValue(.NSLock, defaultValue: [])
    private var urls: [URL]
    
    private init() {
        if let encodedContent = UserDefaults.standard.string(forKey: Self.storageKey), let data = Data(base64Encoded: encodedContent) {
            let datas = (try? JSONDecoder().decode([Data].self, from: data)) ?? []
            self.urls = datas.compactMap { data in
                var isStale: Bool = false
                let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
                if isStale { return url }
                return url
            }
            self.save()
        }
    }
    
    
    /// Save a certain URL to the database.
    ///
    /// - Parameter url: The URL that needs to be saved to the database should come from either `UIDocumentBrowserViewController` or `UIDocumentPickerViewController`.
    static func add(_ url: URL) {
        // Check if it has been added already.
        let urlID = url.withAccessingSecurityScopedResource({ _, _ in try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier})
        for addedURL in Self.share.urls {
            guard let id = addedURL.withAccessingSecurityScopedResource({ _, _ in
                try? addedURL.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier}) else {
                continue
            }
            if let urlID, urlID.isEqual(id) {
                return
            }
        }
        Self.share.urls.append(url)
        Self.share.save()
    }
    
    /// Make the resource referenced by the url accessible to the process.
    ///
    /// - Parameter url: URL for accessing permission wanted.
    /// - Parameter body: Closure for accessing data with a URL within a secure scope. The first parameter of the closure is the current instance.
    /// - Warning: Please do not call the `stopAccessingSecurityScopedResource()` method within this closure.
    static func withAccessingSecurityScopedResource<T>(url: URL, _ body: (URL) throws -> T) rethrows -> T {
        var isOpenedList = [Bool]()
        let urls = Self.share.urls
        for addedURL in urls {
            isOpenedList.append(addedURL.startAccessingSecurityScopedResource())
        }
        defer {
            for (index, url) in urls.enumerated() where isOpenedList[index] {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try url.withAccessingSecurityScopedResource { url, _ in
            try body(url)
        }
    }
    
    /// Clear all URL data in the current database.
    static func cleanAll() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        Self.share.urls = []
    }
    
    private func save() {
        let datas = self.urls.compactMap { url in
            try? url.bookmarkData()
        }
        let encodedContent = try? JSONEncoder().encode(datas).base64EncodedString()
        UserDefaults.standard.set(encodedContent, forKey: Self.storageKey)
    }
    
    
}
