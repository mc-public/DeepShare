//
//  NSString+Encoding.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/14.
//

import Foundation

extension CFStringEncodings {
    var coreEncoding: CFStringEncoding {
        CFStringEncoding(self.rawValue)
    }
    var encoding: String.Encoding {
        .init(rawValue: CFStringConvertEncodingToNSStringEncoding(self.coreEncoding))
    }
}

extension NSString {
    
    /// Convert the text data to string.
    ///
    /// - Parameter data: The data of the text file.
    /// - Parameter encodings: The preferred encodings of the file.
    /// - Parameter allowEncodingDetect: This parameter indicates whether encoding detection is allowed.
    public static func createFromData(_ data: Data, encodings: String.Encoding..., allowEncodingDetect: Bool) throws -> (content: NSString, encoding: String.Encoding) {
        guard let result = NSString.loadFromData(data, encodings: encodings, allowLossyConversion: false, allowEncodingDetection: allowEncodingDetect) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return (result.content, result.encoding)
    }
    
    /// Convert the text data to string.
    ///
    /// - Parameter data: The data of the text file.
    /// - Parameter encoding: The encoding of the file. If use `nil`, this method will try to detect the encoding.
    /// - Parameter allowLossyConversion: This parameter indicates whether lossy conversion is allowed. Please use this parameter with caution. The default value is false.
    public static func createFromData(_ data: Data, encoding: String.Encoding?, allowLossyConversion: Bool = false) throws -> (content: NSString, encoding: String.Encoding, isDataLost: Bool) {
        guard let encoding else {
            guard let result = NSString.loadFromData(data, encodings: UnicodeEncoding.allEncodings, allowLossyConversion: allowLossyConversion, allowEncodingDetection: true) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            return result
        }
        guard let result = NSString.loadFromData(data, encoding: encoding, allowLossyConversion: allowLossyConversion, allowEncodingDetection: false) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return result
    }
    
    /// Open the data as string independently of its encoding.
    ///
    /// - Parameter data: The data of the file.
    public static func createFromData(_ data: Data) throws -> (content: NSString, encoding: String.Encoding) {
        let result = try Self.createFromData(data, encoding: nil, allowLossyConversion: false)
        return (result.content, result.encoding)
    }
}


extension NSString {
    fileprivate static func loadFromData(_ data: Data, encoding: String.Encoding, allowLossyConversion: Bool, allowEncodingDetection: Bool) -> (content: NSString, encoding: String.Encoding, isDataLost: Bool)? {
        Self.loadFromData(data, encodings: [encoding], allowLossyConversion: allowLossyConversion, allowEncodingDetection: allowEncodingDetection)
    }
    
    fileprivate static func loadFromData(_ data: Data, encodings: [String.Encoding], allowLossyConversion: Bool, allowEncodingDetection: Bool) -> (content: NSString, encoding: String.Encoding, isDataLost: Bool)? {
        var externalEncodings: [String.Encoding: Bool] = [.utf16LittleEndian: false]
        encodings.forEach { encoding in
            if externalEncodings.keys.contains(encoding) {
                externalEncodings[encoding] = true
            }
        }
        let fetchResult = { (encodings: [String.Encoding], allowEncodingDetection: Bool) -> (content: NSString, encoding: String.Encoding, isDataLost: Bool)? in
            var result: NSString?
            var isLossy: ObjCBool = false
            let encodings = encodings.map { $0.rawValue as NSNumber } as NSArray
            let encodingValue = NSString.stringEncoding(for: data, encodingOptions: [.allowLossyKey: allowLossyConversion as NSNumber, .suggestedEncodingsKey: encodings, .useOnlySuggestedEncodingsKey: !allowEncodingDetection as NSNumber], convertedString: &result, usedLossyConversion: &isLossy)
            guard let result, encodingValue != 0 else {
                return nil
            }
            return (result, .init(rawValue: encodingValue), isLossy.boolValue)
        }
        if let result = fetchResult(encodings, allowEncodingDetection) {
            return result
        }
        /// Do external encoding check.
        for (encoding, isNeedDetect) in externalEncodings where isNeedDetect {
            if let result = fetchResult([encoding], false) {
                return result
            }
        }
        return nil
    }
}


/// The enumeration of all Unicode encoding types supported by `CloudTextModel`.
fileprivate enum UnicodeEncoding: Sendable, Identifiable {
    public var id: Self { self }
    
    init?(encoding: String.Encoding) {
        switch encoding {
            case .utf8: self = .utf8
            case .utf16: self = .utf16
            case .utf16BigEndian: self = .utf16BigEndian
            case .utf16LittleEndian: self = .utf16LittleEndian
            case .utf32: self = .utf32
            case .utf32BigEndian: self = .utf32BigEndian
            case .utf32LittleEndian: self = .utf32LittleEndian
            default: return nil
        }
    }
    case utf8
    case utf16
    case utf16BigEndian
    case utf16LittleEndian
    case utf32
    case utf32BigEndian
    case utf32LittleEndian
    /// Detect the encoding currently used in the document automatically.
    case automaticDetection
    /// All possible cases in the enumeration.
    ///
    /// Exclude the `.automaticDetection`.
    public static var allCases: [UnicodeEncoding] {
        [.utf8, .utf16, .utf16BigEndian, .utf16LittleEndian, .utf32, .utf32BigEndian, .utf32LittleEndian]
    }
    /// All possible string encoding in the enumeration.
    ///
    /// Exclude the `.automaticDetection`.
    public static var allEncodings: [String.Encoding] {
        UnicodeEncoding.allCases.map { $0.stringEncoding }
    }
    
    /// Indicates the `String.Encoding` encoding corresponding to the current enumeration.
    public var stringEncoding: String.Encoding {
        Encoding(unicode: self).stringEncoding
    }
    
    /// A textual representation of this instance.
    public var description: String {
        Encoding(unicode: self).description
    }
}
/// The enumeration of all text encoding types supported by `CloudTextModel`.
fileprivate  enum Encoding: Identifiable, CustomStringConvertible, Sendable, CaseIterable {
    init(unicode: UnicodeEncoding) {
        switch unicode {
            case .utf8: self = .utf8
            case .utf16: self = .utf16
            case .utf16BigEndian: self = .utf16BigEndian
            case .utf16LittleEndian: self = .utf16LittleEndian
            case .utf32: self = .utf32
            case .utf32BigEndian: self = .utf32BigEndian
            case .utf32LittleEndian: self = .utf32LittleEndian
            case .automaticDetection: self = .utf8
        }
    }
    init?(_ stringCode: UInt) {
        if let encoding = String.Encoding(rawValue: stringCode).encoding {
            self = encoding
        } else { return nil }
    }
    init?(_ encoding: String.Encoding) {
        if let encoding = String.Encoding(rawValue: encoding.rawValue).encoding {
            self = encoding
        } else { return nil }
    }
    case utf8
    case utf16
    case utf16BigEndian
    case utf16LittleEndian
    case utf32
    case utf32BigEndian
    case utf32LittleEndian
    case gb18030
    case ascii
    case nonLossyASCII
    case nextstep
    case macOSRoman
    case japaneseEUC
    case iso2022JP
    case shiftJIS
    case isoLatin1
    case isoLatin2
    case windowsCP1250
    case windowsCP1251
    case windowsCP1252
    case windowsCP1253
    case windowsCP1254
    case symbol
}


extension Encoding {
    /// The stable identity of the entity associated with this instance.
    var id: UInt { self.rawValue }
    /// A textual representation of this instance.
    var description: String {
        return switch self {
            case .ascii: "ASCII"
            case .nextstep: "NextStep"
            case .japaneseEUC: "Japanese EUC"
            case .utf8: "UTF-8"
            case .isoLatin1: "ISO-Latin1"
            case .symbol: "Symbol"
            case .nonLossyASCII: "NonLossy ASCII"
            case .shiftJIS: "Shift JIS"
            case .isoLatin2: "ISO-Latin2"
            case .utf16: "UTF-16"
            case .windowsCP1251: "CP1251"
            case .windowsCP1252: "CP1252"
            case .windowsCP1253: "CP1253"
            case .windowsCP1254: "CP1254"
            case .windowsCP1250: "CP1250"
            case .iso2022JP: "ISO-2022-JP"
            case .macOSRoman: "MacRoman"
            case .utf16BigEndian: "UTF-16(BE)"
            case .utf16LittleEndian: "UTF-16(LE)"
            case .utf32: "UTF-32"
            case .utf32BigEndian: "UTF-32(BE)"
            case .utf32LittleEndian: "UTF-32(LE)"
            case .gb18030: "GB18030-2000"
        }
    }
    /// The raw value that represents the encoding.
    var rawValue: UInt {
        switch self {
            case .ascii:
                NSASCIIStringEncoding
            case .nextstep:
                NSNEXTSTEPStringEncoding
            case .japaneseEUC:
                NSJapaneseEUCStringEncoding
            case .isoLatin1:
                NSISOLatin1StringEncoding
            case .symbol:
                NSSymbolStringEncoding
            case .nonLossyASCII:
                NSNonLossyASCIIStringEncoding
            case .shiftJIS:
                NSShiftJISStringEncoding
            case .isoLatin2:
                NSISOLatin2StringEncoding
            case .windowsCP1250:
                NSWindowsCP1250StringEncoding
            case .windowsCP1251:
                NSWindowsCP1251StringEncoding
            case .windowsCP1252:
                NSWindowsCP1252StringEncoding
            case .windowsCP1253:
                NSWindowsCP1253StringEncoding
            case .windowsCP1254:
                NSWindowsCP1254StringEncoding
            case .iso2022JP:
                NSISO2022JPStringEncoding
            case .macOSRoman:
                NSMacOSRomanStringEncoding
            case .utf8:
                NSUTF8StringEncoding
            case .utf16:
                NSUTF16StringEncoding
            case .utf16BigEndian:
                NSUTF16BigEndianStringEncoding
            case .utf16LittleEndian:
                NSUTF16LittleEndianStringEncoding
            case .utf32:
                NSUTF32StringEncoding
            case .utf32BigEndian:
                NSUTF32BigEndianStringEncoding
            case .utf32LittleEndian:
                NSUTF32LittleEndianStringEncoding
            case .gb18030:
                CFStringConvertEncodingToNSStringEncoding(CFStringEncodings.GB_18030_2000.coreEncoding)
        }
    }
    
    /// Indicates the `String.Encoding` encoding corresponding to the current enumeration.
    var stringEncoding: String.Encoding {
        .init(rawValue: self.rawValue)
    }
    
    /// Indicates the `NSString` encoding corresponding to the current enumeration.
    var cocoaEncoding: UInt {
        self.rawValue
    }
}

extension String.Encoding {
    fileprivate var encoding: Encoding? {
        return switch self.rawValue {
            case NSASCIIStringEncoding: .ascii
            case NSNEXTSTEPStringEncoding: .nextstep
            case NSJapaneseEUCStringEncoding: .japaneseEUC
            case NSISOLatin1StringEncoding: .isoLatin1
            case NSSymbolStringEncoding: .symbol
            case NSNonLossyASCIIStringEncoding: .nonLossyASCII
            case NSShiftJISStringEncoding: .shiftJIS
            case NSISOLatin2StringEncoding: .isoLatin2
            case NSWindowsCP1250StringEncoding: .windowsCP1250
            case NSWindowsCP1251StringEncoding: .windowsCP1251
            case NSWindowsCP1252StringEncoding: .windowsCP1252
            case NSWindowsCP1253StringEncoding: .windowsCP1253
            case NSWindowsCP1254StringEncoding: .windowsCP1254
            case NSISO2022JPStringEncoding: .iso2022JP
            case NSMacOSRomanStringEncoding: .macOSRoman
            case NSUTF8StringEncoding: .utf8
            case NSUTF16StringEncoding: .utf16
            case NSUTF16BigEndianStringEncoding: .utf16BigEndian
            case NSUTF16LittleEndianStringEncoding: .utf16LittleEndian
            case NSUTF32StringEncoding: .utf32
            case NSUTF32BigEndianStringEncoding: .utf32BigEndian
            case NSUTF32LittleEndianStringEncoding: .utf32LittleEndian
            case CFStringConvertEncodingToNSStringEncoding(CFStringEncodings.GB_18030_2000.coreEncoding): .gb18030
            default: nil
        }
    }
}
