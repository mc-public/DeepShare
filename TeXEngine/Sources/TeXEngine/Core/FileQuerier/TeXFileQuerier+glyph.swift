//
//  TeXFileQuerier+glyph.swift
//
//
//  Created by 孟超 on 2024/2/17.
//

import Foundation
import WebKit

class TeXGlyphQuerier {
    weak var fileQuerier: TeXFileQuerier?
    
    init(fileQuerier: TeXFileQuerier) {
        self.fileQuerier = fileQuerier
    }
    
    private func loadData(from url: URL) async -> Data? {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: try? Data(contentsOf: url))
            }
        }
    }
    
    func searchFile(urlSchemeTask: WKURLSchemeTask, requestURL: URL) {
        let setURLSchemeDidFail = {
            urlSchemeTask.didFailWithError(TeXFileQuerier.URLTaskFail.URLResolutionFailure)
        }
        guard let url = urlSchemeTask.request.url else {
            setURLSchemeDidFail()
            return
        }
        guard let json = urlSchemeTask.request.value(forHTTPHeaderField: "pdfTeX-Font-Glyph-Query-Info"), let jsonData = json.data(using: .utf8) else {
            setURLSchemeDidFail()
            return
        }
        struct EnginePKGlyphRequest: Codable {
            let font_name: String
            let dpi: Float
            init(font_name: String, dpi: Float) {
                self.font_name = font_name
                self.dpi = max(0, dpi)
            }
        }
        guard let fileRequest = try? JSONDecoder().decode(EnginePKGlyphRequest.self, from: jsonData) else {
            setURLSchemeDidFail()
            return
        }
        Task { @MainActor in
            guard let engine = self.fileQuerier?.texEngine else {
                setURLSchemeDidFail()
                return
            }
            let setURLSchemeTaskNotFound = {
                if TeXFileQuerier.usingDetailedLog {
                    print("[TeXEngine][FileQuerier][format=\(TeXFileType.kpse_pk_format.rawValue)]字形文件未找到。索取文件名: \(fileRequest.font_name)")
                }
                let respone = URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
                urlSchemeTask.didReceive(respone)
                urlSchemeTask.didFinish()
            }
            guard let queryResult = await engine.fileQuerier?.search(for: fileRequest.font_name, with: .kpse_pk_format) else {
                setURLSchemeDidFail() /* 此时 fileQuerier 被释放 */
                return
            }
            let queryResultURL: URL
            switch queryResult {
            case let .texlive(url: url):
                queryResultURL = url
            default:
                setURLSchemeTaskNotFound()
                return
            }
            guard let queryResultData = await self.loadData(from: queryResultURL) else {
                setURLSchemeTaskNotFound()
                return
            }
            var headerFields = [String : String]()
            headerFields["Content-Length"] = "\(queryResultData.count)"
            headerFields["Content-Type"] = queryResultURL.mimeType
            headerFields["PK-Glyph-Path"] = queryResultURL.versionPath
            headerFields["PK-Glyph-DPI"] = "\(fileRequest.dpi)"
            guard let respones = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields) else {
                setURLSchemeTaskNotFound()
                return
            }
            if TeXFileQuerier.usingDetailedLog {
                print("[TeXEngine][FileQuerier][format=\(TeXFileType.kpse_pk_format.rawValue)]字形文件已找到。索取文件名: \(fileRequest.font_name)")
            }
            urlSchemeTask.didReceive(respones)
            urlSchemeTask.didReceive(queryResultData)
            urlSchemeTask.didFinish()
        }
    }

}
