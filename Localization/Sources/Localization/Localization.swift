//
//  Localization.swift
//  Localization
//
//  Created by 孟超 on 2024/8/19
//

import Foundation

/// Structure for storing all localizable strings.
public struct LocalizationStorage: Sendable {
    private init() {}
    /// Class for storing titles of all buttons.
    ///
    /// Contains titles only for `UIButton` and `Button`.
    public struct Button { private init () {} }
    /// Structure for storing titles of all `Section` in `List`.
    public struct Section { private init () {} }
    /// Structure for storing label titles of all `Label`.
    public struct Label { private init () {} }
    /// Structure for storing titles of all `Text`.
    ///
    /// Stored text should not intersect with other types of localized text.
    public struct Text { private init () {} }
    /// Structure for storing all Alert titles.
    ///
    /// Contains titles only for `UIAlert` and `Alert`.
    public struct Alert { private init () {} }
}


/// Structure for comments available for viewing during localization.
public struct LocalizationComment: Sendable {
    public static let button: Self = .init("Button")
    public static let section: Self = .init("Section")
    public static let label: Self = .init("Label")
    public static let text: Self = .init("Text")
    public static let alert: Self = .init("Alert")
    /// This parameter represents a string literal of the comment information.
    public let rawValue: StaticString
    /// Initialize a comment with the specified string literal.
    public init(_ rawValue: StaticString) {
        self.rawValue = rawValue
    }
    /// Initialize a comment.
    public static func new() -> Self {
        .init(StaticString())
    }
}


/// Macro for performing automatic localization conversion.
///
/// - Parameter content: This parameter represents the string literal that one wants to localize.
/// - Parameter comment: This parameter represents the comment information available for review during translation.
@available(iOS 15.0, *)
@freestanding(expression)
public macro localized(_ content: String.LocalizationValue, _ comment: LocalizationComment) -> String = #externalMacro(module: "LocalizationMacros", type: "LocalizationMacro")

/// Macro for performing automatic localization conversion.
///
/// - Parameter content: This parameter represents the string literal that one wants to localize.
/// - Parameter type: The type corresponding to the annotations you want to add will be used as the annotation itself.
@available(iOS 15.0, *)
@freestanding(expression)
public macro localized<T>(_ content: String.LocalizationValue, _ type: T.Type) -> String = #externalMacro(module: "LocalizationMacros", type: "LocalizationTypeMacro")


/// Macro for performing automatic localization conversion.
///
/// - Parameter content: This parameter represents the string literal that one wants to localize.
@available(iOS 15.0, *)
@freestanding(expression)
public macro localized(_ content: String.LocalizationValue) -> String = #externalMacro(module: "LocalizationMacros", type: "LocalizationMacro")
