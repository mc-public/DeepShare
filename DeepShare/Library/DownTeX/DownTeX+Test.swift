//
//  DownTeX+Test.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/23.
//

#if DEBUG

import UIKit

extension DownTeX {
    /// Test all available compile cases.
    func test() {
        let preferredSize = CGSize(width: 375, height: 375)
        guard let layoutResult = QATemplateManager.current.renderingResult(for: QATemplateManager.current.defaultTemplate, preferredSize: preferredSize) else {
            return
        }
        Task {
            for model in QADataManager.current.allModels {
                for fontSize in FontSize.allCases {
                    let pageImage = await layoutResult.totalImage()
                    let newContentRect = layoutResult.textRect
                    let config = DownTeX.ConvertConfiguration(
                        fontSize: fontSize,
                        pageSize: layoutResult.size,
                        contentRect: newContentRect,
                        allowTextOverflow: false,
                        pageImage: pageImage,
                        titleImage: nil,
                        titleRect: nil
                    )
                    do {
                        _ =  try await DownTeX.current.convertToPDFData(markdown: model.answer, config: config)
                    } catch {
                        print("[\(Self.self)][\(#function)] Test Failured. Question: `\(model.question)`. Error: `\(error)`.")
                    }
                }
            }
        }
    }
}
#endif
