//
//  TeXFileQuerier+regular.swift
//
//
//  Created by 孟超 on 2024/2/16.
//

import Foundation
import WebKit

/// 供所有引擎进行常规文件查询的类
///
/// 该类同时供 `XeTeX` 和 `pdfTeX` 使用以进行非字体、非字形的 `TeX` 文件查询。
@MainActor
class TeXRegularQuerier {
    
    /// 当前执行常规文件查询的文件查询器
    weak var fileQuerier: TeXFileQuerier?
    
    struct EngineFileRequest: Codable {
        let name: String
        let format: Int
        init(_ name: String, _ format: Int) {
            self.name = name
            self.format = format
        }
    }
    
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
        guard let json = urlSchemeTask.request.value(forHTTPHeaderField: "File-Info-JSON"), let jsonData = json.data(using: .utf8) else {
            setURLSchemeDidFail()
            return
        }
        guard let fileRequest = try? JSONDecoder().decode(EngineFileRequest.self, from: jsonData) else {
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
                    print("[TeXEngine][FileQuerier][format=\(fileRequest.format)]文件未找到。索取文件名: \(fileRequest.name)")
                }
                let respone = URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
                urlSchemeTask.didReceive(respone)
                urlSchemeTask.didFinish()
            }
            guard let queryResult = await engine.fileQuerier?.search(for: fileRequest.name, with: .init(rawValue: fileRequest.format) ?? .kpse_tex_format) else {
                setURLSchemeDidFail() /* 此时 fileQuerier 被释放 */
                return
            }
            let queryResultURL: URL
            let resourceTypeCode: String
            switch queryResult {
            case .notFound:
                setURLSchemeTaskNotFound()
                return
            case let .texProject(url: url):
                queryResultURL = url
                resourceTypeCode = "200"
            case let .dynamic(url: url):
                queryResultURL = url
                resourceTypeCode = "300"
            case let .texlive(url: url):
                queryResultURL = url
                resourceTypeCode = "400"
            }
            guard let queryResultData = await self.loadData(from: queryResultURL) else {
                setURLSchemeTaskNotFound()
                return
            }
            var headerFields = [String : String]()
            headerFields["Content-Length"] = "\(queryResultData.count)"
            headerFields["Content-Type"] = queryResultURL.mimeType
            headerFields["File-Absolute-Path"] = queryResultURL.versionPath//engine.supportedUnicode ? queryResultURL.versionPath : (queryResultURL.versionPath as NSString).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            //headerFields["Path-Percent-Encoded"] = engine.supportedUnicode ? "0" : "1"
            headerFields["File-Resource-Type"] = resourceTypeCode
            guard let respones = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields) else {
                setURLSchemeTaskNotFound()
                return
            }
            if TeXFileQuerier.usingDetailedLog {
                print("[TeXEngine][FileQuerier][format=\(fileRequest.format)] 文件已找到。索取文件名: \(fileRequest.name)")
            }
            urlSchemeTask.didReceive(respones)
            urlSchemeTask.didReceive(queryResultData)
            urlSchemeTask.didFinish()
        }
    }
}
