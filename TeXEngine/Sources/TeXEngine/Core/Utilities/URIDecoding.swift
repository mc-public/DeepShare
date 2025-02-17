//
//  URIDecoding.swift
//  
//
//  Created by 孟超 on 2023/7/24.
//

import Foundation
import JavaScriptCore

extension NSString {
    @objc func ped_encodeURI() -> NSString {
        let encoded = (self as String).ped_encodeURI()
        return encoded as NSString
    }
    
    @objc func ped_encodeURIComponent() -> NSString {
        let encoded = (self as String).ped_encodeURIComponent()
        return encoded as NSString
    }
    
    @objc func ped_decodeURI() -> NSString {
        let decoded = (self as String).ped_decodeURI()
        return decoded as NSString
    }
    
    @objc func ped_decodeURIComponent() -> NSString {
        let decoded = (self as String).ped_decodeURIComponent()
        return decoded as NSString
    }
}


enum PercentEncoding: String {
    case encodeURI, encodeURIComponent, decodeURI, decodeURIComponent
    
    func evaluate(string: String) -> String {
        guard let context = JSContext() else {
            return ""
        }
        let inputValue = JSValue(object: string, in: context)
        context.setObject(inputValue, forKeyedSubscript: "input" as NSString)
        context.evaluateScript("var output = \(rawValue)(input);")
        let outputValue: JSValue = context.objectForKeyedSubscript("output")
        return outputValue.toString()
    }
}

extension String {
    func ped_encodeURI() -> String {
        return PercentEncoding.encodeURI.evaluate(string: self)
    }
    
    func ped_encodeURIComponent() -> String {
        return PercentEncoding.encodeURIComponent.evaluate(string: self)
    }
    
    func ped_decodeURI() -> String {
        return PercentEncoding.decodeURI.evaluate(string: self)
    }
    
    func ped_decodeURIComponent() -> String {
        return PercentEncoding.decodeURIComponent.evaluate(string: self)
    }
}
