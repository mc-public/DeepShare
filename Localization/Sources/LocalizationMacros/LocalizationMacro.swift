//
//  LocalizationMacro.swift
//  Localization
//
//  Created by 孟超 on 2024/8/19
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LocalizationMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard node.argumentList.count >= 1 else {
            fatalError("Localization Error: This macro requires two parameters. Current count is \(node.argumentList.count).")
        }
        let argument1 = node.argumentList.first!
        
        if node.argumentList.count == 1 {
            return "String(localized: \(argument1))"
        }
        let argument2 = node.argumentList.last!
        if "\(argument2)".hasPrefix(".") {
            var newArgument2 = "\(argument2)"
            newArgument2.removeFirst()
            let first = newArgument2.removeFirst().uppercased().first!
            newArgument2.insert(first, at: newArgument2.startIndex)
            return "String(localized: \(argument1) comment: \(literal: newArgument2))"
        } else if "\(argument2)".hasPrefix("LocalizationComment") {
            var newArgument2 = "\(argument2)"
            newArgument2.removeFirst("LocalizationComment.".count)
            let first = newArgument2.removeFirst().uppercased().first!
            newArgument2.insert(first, at: newArgument2.startIndex)
            return "String(localized: \(argument1) comment: \(literal: newArgument2))"
        } else {
            fatalError("Localization Error: The format of the second parameter is incorrect. Please pass in a literal static property of `LocalizationComment`.")
        }
    }
}

public struct LocalizationTypeMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard   node.argumentList.count == 2,
                let argument1 = node.argumentList.first,
                let argument2 = node.argumentList.last 
        else {
            fatalError("Localization Error: This macro requires two parameters. Current count is \(node.argumentList.count).")
        }
        if "\(argument2)".hasPrefix("Self") {
            fatalError("Localization Error: The second parameter must use the display name of the type, not `Self`.")
        } else {
            
            var newArgument2 = "\(argument2)"
            if newArgument2.hasPrefix("LocalizationCenter.") {
                newArgument2.removeFirst("LocalizationCenter.".count)
            }
            if newArgument2.hasPrefix("LocalizationStorage.") {
                newArgument2.removeFirst("LocalizationStorage.".count)
            }
            if newArgument2.hasSuffix(".self") {
                newArgument2.removeLast(".self".count)
            }
            return "String(localized: \(argument1) comment: \(literal: newArgument2))"
        }
    }
}

@main
struct LocalizationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizationMacro.self, LocalizationTypeMacro.self
    ]
}

