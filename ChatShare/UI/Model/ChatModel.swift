//
//  ChatModel.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/4.
//

struct ChatModel: RawRepresentable, CaseIterable, Identifiable, Hashable {
    var id: String {
        self.rawValue
    }
    static var allCases: [ChatModel] {
        [deepseek_R1, deepseek_V3, chatgpt_o3_mini, chatgpt_4o, chatgpt_4o_mini, chatgpt_o1, chatgpt_o1_mini]
    }
    
    var rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
// swiftlint:disable all
    static let deepseek_R1 = Self(rawValue: "DeepSeek R1")
    static let deepseek_V3 = Self(rawValue: "DeepSeek V3")
    static let chatgpt_o3_mini = Self(rawValue: "GPT o3-mini")
    static let chatgpt_4o = Self(rawValue: "GPT 4o")
    static let chatgpt_4o_mini = Self(rawValue: "GPT 4o-mini")
    static let chatgpt_o1 = Self(rawValue: "GPT o1")
    static let chatgpt_o1_mini = Self(rawValue: "GPT o1-mini")
}
