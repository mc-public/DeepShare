//
//  CTFontKey.swift
//  
//
//  Created by 孟超 on 2023/7/28.
//

@preconcurrency import CoreText
import Foundation

extension CTFont {
    
    /// The name keys used by `CTFont` object.
    public struct NameKey: Hashable, Equatable, Sendable {
        public var rawValue: CFString
        /// The name specifier for the copyright name.
        public static let copyrightName: Self = .init(kCTFontCopyrightNameKey)
        /// The name specifier for the family name.
        public static let familyName: Self = .init(kCTFontFamilyNameKey)
        /// The name specifier for the subfamily name.
        public static let subFamilyName: Self = .init(kCTFontSubFamilyNameKey)
        /// The name specifier for the style name.
        public static let styleName: Self = .init(kCTFontStyleNameKey)
        /// The name specifier for the unique name.
        public static let uniqueName: Self = .init(kCTFontUniqueNameKey)
        /// The name specifier for the full name.
        public static let fullName: Self = .init(kCTFontFullNameKey)
        /// The name specifier for the version name.
        public static let versionName: Self = .init(kCTFontVersionNameKey)
        /// The name specifier for the PostScript name.
        public static let postScriptName: Self = .init(kCTFontPostScriptNameKey)
        /// The name specifier for the trademark name.
        public static let trademarkName: Self = .init(kCTFontTrademarkNameKey)
        /// The name specifier for the manufacturer name.
        public static let manufacturerName: Self = .init(kCTFontManufacturerNameKey)
        /// The name specifier for the designer name.
        public static let designerName: Self = .init(kCTFontDesignerNameKey)
        /// The name specifier for the description name.
        public static let descriptionName: Self = .init(kCTFontDescriptionNameKey)
        /// The name specifier for the vendor URL name.
        public static let vendorURLName: Self = .init(kCTFontVendorURLNameKey)
        /// The name specifier for the designer name.
        public static let designerURLName: Self = .init(kCTFontDesignerURLNameKey)
        /// The name specifier for the license name.
        public static let licenseName: Self = .init(kCTFontLicenseNameKey)
        /// The name specifier for the license URL name.
        public static let licenseURLName: Self = .init(kCTFontLicenseURLNameKey)
        /// The name specifier for the sample text name string.
        public static let sampleTextName: Self = .init(kCTFontSampleTextNameKey)
        /// The name specifier for the PostScript character identifier (`CID`) font name.
        public static let postScriptCIDName: Self = .init(kCTFontPostScriptCIDNameKey)
        init(_ rawValue: CFString) {
            self.rawValue = rawValue
        }
    }
    
    
    public struct Attribute: Hashable, Equatable, Sendable {
        
        var rawValue: CFString
        
        init(_ rawValue: CFString) {
            self.rawValue = rawValue
        }
        
        /**
            The font URL.
            
            This is the key for accessing the font URL from the font descriptor. The value associated with this key is a `CFURLRef`.
        */
        public static let url = Self(kCTFontURLAttribute)
        
        /**
            The PostScript name.
            
            This is the key for retrieving the PostScript name from the font descriptor. When matching, this is treated more generically: the system first tries to find fonts with this `PostScript` name. If none is found, the system tries to find fonts with this family name, and, finally, if still nothing, tries to find fonts with this display name. The value associated with this key is a `CFStringRef`. If unspecified, defaults to "Helvetica", if unavailable falls back to global font cascade list.
        */
        @available(iOS 3.2, *)
        public static let name = Self(kCTFontNameAttribute)
        /**
            The display name.
            
            This is the key for accessing the name used to display the font. Most commonly this is the full name. The value associated with this key is a `CFStringRef`.
        */
        @available(iOS 3.2, *)
        public static let displayName = Self(kCTFontDisplayNameAttribute)
        /**
            The family name.
            
            This is the key for accessing the family name from the font descriptor. The value associated with this key is a `CFStringRef`.
        */
        @available(iOS 3.2, *)
        public static let familyName = Self(kCTFontFamilyNameAttribute)
        /**
            The style name.
            
            This is the key for accessing the style name of the font. This name represents the designer's description of the font's style. The value associated with this key is a `CFStringRef`.
        */
        @available(iOS 3.2, *)
        public static let styleName = Self(kCTFontStyleNameAttribute)
        /**
            The font traits dictionary.
            
            This is the key for accessing the dictionary of font traits for stylistic information. See `CTFontTraits.h` for the list of font traits. The value associated with this key is a `CFDictionaryRef`.
        */
        @available(iOS 3.2, *)
        public static let traits = Self(kCTFontTraitsAttribute)
        /**
            The font variation dictionary.
            
            This key is used to obtain the font variation instance as a `CFDictionaryRef`. If specified in a font descriptor, fonts with the specified axes will be primary match candidates, if no such fonts exist, this attribute will be ignored.
        */
        @available(iOS 3.2, *)
        public static let variation = Self(kCTFontVariationAttribute)
        /**
            An array of variation axis dictionaries or `nil` if the font does not support variations. Each variation axis dictionary contains the five `kCTFontVariationAxis` keys.
            
            Before macOS 13.0 and iOS 16.0 this attribute is not accurate and `CTFontCopyVariationAxes()` should be used instead.
        */
        @available(iOS 11.0, *)
        public static let variationAxes = Self(kCTFontVariationAxesAttribute)
        /**
            The font point size.
            
            This key is used to obtain or specify the font point size. Creating a font with this unspecified will default to a point size of `12.0`. The value for this key is represented as a `CFNumberRef`.
        */
        @available(iOS 3.2, *)
        public static let size = Self(kCTFontSizeAttribute)
        /**
            The font transformation matrix.
            
            This key is used to specify the font transformation matrix when creating a font. The default value is `CGAffineTransformIdentity`. The value for this key is a CFDataRef containing a CGAffineTransform, of which only the `a`, `b`, `c`, and d fields are used.
        */
        @available(iOS 3.2, *)
        public static let matrix = Self(kCTFontMatrixAttribute)
        /**
            The font cascade list.
            
            This key is used to specify or obtain the cascade list used for a font reference. The cascade list is a `CFArray` containing `CTFontDescriptor`. If unspecified, the global cascade list is used. This list is not consulted for private-use characters on OS X 10.10, iOS 8, or earlier.
        */
        @available(iOS 3.2, *)
        public static let cascadeList = Self(kCTFontCascadeListAttribute)
        /**
            The font Unicode character coverage set.
            
            The value for this key is a `CFCharacterSet`. Creating a font with this attribute will restrict the font to a subset of its actual character set.
        */
        @available(iOS 3.2, *)
        public static let characterSet = Self(kCTFontCharacterSetAttribute)
        /**
            The list of supported languages.
            
            The value for this key is a `CFArray` of `CFString` language identifiers conforming to UTS #35. It can be requested from any font. If present in a descriptor used for matching, only fonts supporting the specified languages will be returned.
        */
        @available(iOS 3.2, *)
        public static let languages = Self(kCTFontLanguagesAttribute)
        /**
            The baseline adjustment to apply to font metrics.
            
            The value for this key is a floating-point `CFNumberRef`. This is primarily used when defining font descriptors for a cascade list to keep the baseline of all fonts even.
        */
        @available(iOS 3.2, *)
        public static let baselineAdjust = Self(kCTFontBaselineAdjustAttribute)
        /**
            The Macintosh encodings (legacy script codes).
         
            The value associated with this key is a `CFNumberRef` containing a bitfield of the script codes in <CoreText/SFNTTypes.h>; bit 0 corresponds to `kFontRomanScript`, and so on. This attribute is provided for legacy compatibility.
        */
        @available(iOS 3.2, *)
        public static let macintoshEncodings = Self(kCTFontMacintoshEncodingsAttribute)
        /**
            The array of font features.
         
            This key is used to specify or obtain the font features for a font reference. The value associated with this key is a CFArrayRef of font feature dictionaries. This features list contains the feature information from the 'feat' table of the font. See the `CTFontCopyFeatures()` API in `CTFont`.
        */
        @available(iOS 3.2, *)
        public static let features = Self(kCTFontFeaturesAttribute)
        /**
            The array of typographic feature settings.
            
            This key is used to specify an array of zero or more feature settings. Each setting dictionary indicates which setting should be applied. In the case of duplicate or conflicting settings the last setting in the list will take precedence. In the case of AAT settings, it is the caller's responsibility to handle exclusive and non-exclusive settings as necessary.
         
            An AAT setting dictionary contains a tuple of a `kCTFontFeatureTypeIdentifierKey` key-value pair and a `kCTFontFeatureSelectorIdentifierKey` key-value pair.
        
            An OpenType setting dictionary contains a tuple of a `kCTFontOpenTypeFeatureTag` key-value pair and a `kCTFontOpenTypeFeatureValue` key-value pair.

            Starting with OS X 10.10 and iOS 8.0, settings are also accepted (but not returned) in the following simplified forms:
         
            An OpenType setting can be either an array pair of tag string and value number, or a tag string on its own. An unspecified value enables the feature and a value of `zero` disables it.
         
            An AAT setting can be specified as an array pair of type and selector numbers. For example: `kUpperCaseType`, `kUpperCaseSmallCapsSelector`.
        */
        @available(iOS 3.2, *)
        public static let featureSettings = Self(kCTFontFeatureSettingsAttribute)
        /**
            Specifies advance width.
            
            This key is used to specify a constant advance width, which affects the glyph metrics of any font instance created with this key; it overrides font values and the font transformation matrix, if any. The value associated with this key must be a `CFNumberRef`.

            Starting with macOS 10.14 and iOS 12.0, this only affects glyph advances that have non-zero width when this attribute is not present.
        */
        @available(iOS 3.2, *)
        public static let fixedAdvance = Self(kCTFontFixedAdvanceAttribute)
        /**
            The orientation attribute.
            
            This key is used to specify a particular orientation for the glyphs of the font. The value associated with this key is a int as a `CFNumberRef`. If you want to receive vertical metrics from a font for vertical rendering, specify `kCTFontVerticalOrientation`. If unspecified, the font will use its native orientation.
        */
        @available(iOS 3.2, *)
        public static let orientation = Self(kCTFontOrientationAttribute)

        /**
            Specifies the recognized format of the font.
            
            The attribute is used to specify or obtain the format of the font. The returned value is a `CFNumber` containing one of the constants defined below.
        */
        public static let format = Self(kCTFontFormatAttribute)

        /**
            Specifies the font descriptor's registration scope.
            
            The attribute is used to specify or obtain the font registration scope. The value returned is a `CFNumberRef` containing one of the `CTFontManagerScope` enumerated values. A value of `nil` can be returned for font descriptors that are not registered.
        */
        @available(iOS 3.2, *)
        public static let registrationScope = Self(kCTFontRegistrationScopeAttribute)
        /**
            The font descriptors priority when resolving duplicates and sorting match results.
            
            This key is used to obtain or specify the font priority. The value returned is a `CFNumberRef` containing an integer value as defined below. The higher the value, the higher the priority of the font. Only registered fonts will have a priority. Unregistered font descriptors will return `nil`.
        */
        @available(iOS 3.2, *)
        public static let priority = Self(kCTFontPriorityAttribute)

        /**
            The font enabled state.
            
            The value associated with this key is a `CFBoolean`. Unregistered font descriptors will return `nil`, which is equivalent to false.
        */
        @available(iOS 3.2, *)
        public static let enabled = Self(kCTFontEnabledAttribute)

        /**
            The font downloadable state.
            
            The value associated with this key is a `CFBoolean`. If it is `true`, CoreText attempts to download a font if necessary when matching a descriptor.
        */
        @available(iOS 6.0, *)
        public static let downloadable = Self(kCTFontDownloadableAttribute)

        /**
            The download state.
            
            The value associated with this key is a `CFBoolean`. If it is `true`, corresponding `FontAsset` has been downloaded. (but still it may be necessary to call appropriate API in order to use the font in the `FontAsset`.)
        */
        @available(iOS 7.0, *)
        public static let downloaded = Self(kCTFontDownloadedAttribute)

        /**
            The point size at which this font is intended to be used.
            
            The value is a `CFNumber` used to activate size-specific (not linearly scaled) metrics. Starting with macOS 10.14 and iOS 12.0, the `CFString` "auto" can be used instead to request an optical size matching the point size. Starting with macOS 10.15 and iOS 13.0, the `CFString` "none" can be used instead to explicitly disable automatic optical sizing enabled by the font.
        */
        @available(iOS 7.0, *)
        public static let opticalSize = Self(kCTFontOpticalSizeAttribute)
        
        @available(iOS 13.0, *)
        public static let registrationUserInfo = Self(kCTFontRegistrationUserInfoAttribute)
    }
}


/// Constants represent string attribute names in CoreText.
public struct CTAttributeName: Sendable {
    public var rawValue: CFString
    /// The font of the text to which this attribute applies.
    ///
    /// The value associated with this attribute must be a `CTFont` object. Default is Helvetica 12.
    public static let font: Self = .init(kCTFontAttributeName)
    /// The amount to kern the next character.
    ///
    /// The value associated with this attribute must be a `CFNumber` float. Default is standard kerning. The kerning attribute indicates how many points the following character should be shifted from its default offset as defined by the current character's font in points: a positive kern indicates a shift farther away from and a negative kern indicates a shift closer to the current character. If this attribute is not present, standard kerning is used. If this attribute is set to 0.0, no kerning is done at all.
    public static let kern: Self = .init(kCTKernAttributeName)
    /// The type of ligatures to use.
    ///
    /// The value associated with this attribute must be a `CFNumber` object. Default is an integer value of `1`. The ligature attribute determines what kinds of ligatures should be used when displaying the string. A value of `0` indicates that only ligatures essential for proper rendering of text should be used. A value of `1` indicates that standard ligatures should be used, and `2` indicates that all available ligatures should be used. Which ligatures are standard depends on the script and possibly the font. Arabic text, for example, requires ligatures for many character sequences but has a rich set of additional ligatures that combine characters. English text has no essential ligatures, and typically has only two standard ligatures, those for "fi" and "fl"—all others are considered more advanced or fancy.
    public static let ligature: Self = .init(kCTLigatureAttributeName)
    /// The foreground color of the text to which this attribute applies.
    ///
    /// The value associated with this attribute must be a `CGColor` object. Default value is `black`.
    public static let foregroundColor: Self = .init(kCTForegroundColorAttributeName)
    /// Sets a foreground color using the context's fill color.
    ///
    /// Value must be a `CFBoolean` object. Default is `kCFBooleanFalse`. The reason this exists is because an `NSAttributedString` object defaults to a `black` color if no color attribute is set. This forces Core Text to set the color in the context. This attribute allows developers to sidestep this, making Core Text set nothing but font information in the `CGContext`. If set, this attribute also determines the color used by `style`, in which case it overrides the foreground color.
    public static let foregroundColorFromContext: Self = .init(kCTForegroundColorFromContextAttributeName)
    /// The paragraph style of the text to which this attribute applies.
    ///
    /// A paragraph style object is used to specify things like line alignment, tab rulers, writing direction, and so on. Value must be a `CTParagraphStyle object`. Default is an empty `CTParagraphStyle` object.
    public static let paragraphStyle: Self = .init(kCTParagraphStyleAttributeName)
    /// The stroke width.
    ///
    /// Value must be a `CFNumber` object. Default value is `0.0`, or no stroke. This attribute, interpreted as a percentage of font point size, controls the text drawing mode: positive values effect drawing with stroke only; negative values are for stroke and fill. A typical value for outlined text is `3.0`.
    public static let strokeWidth: Self = .init(kCTStrokeWidthAttributeName)
    /// The stroke color.
    ///
    /// Value must be a `CGColor` object. Default is the foreground color.
    public static let color: Self = .init(kCTStrokeColorAttributeName)
    /// Controls vertical text positioning.
    ///
    /// Value must be a `CFNumber` object. Default is integer value `0`. If supported by the specified font, a value of `1` enables superscripting and a value of `-1` enables subscripting.
    public static let superscript: Self = .init(kCTSuperscriptAttributeName)
    /// The underline color.
    ///
    /// Value must be a `CGColor` object. Default is the foreground color.
    public static let underlineColor: Self = .init(kCTUnderlineColorAttributeName)
    /// The style of underlining, to be applied at render time, for the text to which this attribute applies.
    ///
    /// Value must be a `CFNumber` object. Default is `none`. Set a value of something other than `none` to draw an underline. In addition, the constants listed in `CTUnderlineStyleModifiers` can be used to modify the look of the underline. The underline color is determined by the text's foreground color.
    public static let underlineStyle: Self = .init(kCTUnderlineStyleAttributeName)
    /// The orientation of the glyphs in the text to which this attribute applies.
    ///
    /// Value must be a `CFBoolean` object. Default is `kCFBooleanFalse`. A value of `kCFBooleanFalse` indicates that horizontal glyph forms are to be used; `kCFBooleanTrue` indicates that vertical glyph forms are to be used.
    public static let verticalForms: Self = .init(kCTVerticalFormsAttributeName)
    /// The glyph info object to apply to the text associated with this attribute.
    ///
    /// Value must be a `CTGlyphInfo` object. The glyph specified by this `CTGlyphInfo` object is assigned to the entire attribute range, provided that its contents match the specified base string and that the specified glyph is available in the font specified by `font` attribute name.
    public static let CTglyphInfo: Self = .init(kCTGlyphInfoAttributeName)
    /// The run-delegate object to apply to an attribute range of the string.
    ///
    /// The value must be a `CTRunDelegate` object. The run delegate controls such typographic traits as glyph ascent, descent, and width. The values returned by the embedded run delegate apply to each glyph resulting from the text in that range. Because an embedded object is only a display-time modification, you should avoid applying this attribute to a range of text with complex behavior, such as text having a change of writing direction or having combining marks. It is thus recommended you apply this attribute to a range containing the single character `U+FFFC`.
    public static let CTRunDelegate: Self = .init(kCTRunDelegateAttributeName)
    /// Vertical offset for text position.
    ///
    /// The value of this attribute must be a `CFNumber` float. The default is standard positioning, following the baselines of the fonts used.
    ///
    /// The baseline offset attribute indicates how many points the characters should be shifted perpendicular to their baseline. For horizontal text, a positive baseline value indicates a shift above the text baseline, and a negative baseline value indicates a shift below the text baseline. For vertical text, a positive baseline value indicates a shift to the right of the text baseline, and a negative baseline value indicates a shift to the left of the text baseline. If this value is set to `0.0`, no baseline shift will be performed.
    ///
    /// > This attribute is different from the `baselineOffset` of `NSAttributedString`. If you are writing code for `TextKit`, you need to use the `baselineOffset` of `NSAttributedString`.
    public static let baselineOffset: Self = .init(kCTBaselineOffsetAttributeName)
    /// The tracking for the text.
    ///
    /// The value associated with this attribute must be a `CFNumber` float. The default is `0` (no tracking).
    ///
    /// Tracking adds space, in points, between the specified character cluster. A positive value increases the spacing between characters, while a negative value brings the characters closer together. For example, setting `tracking` attribute name to `0.1` adds `0.1` point of spacing between each character of the text.
    ///
    /// The effect of this attribute is similar to `kern` attribute name, but it treats tracking as trailing whitespace and a nonzero amount disables nonessential ligatures, unless overridden by the presence of `ligature` attribute name.
    ///
    /// > Important:
    /// If you apply both `tracking` attribute name and `kern` attribute name, `tracking` attribute name supersedes `kern` attribute name.
    public static let tracking: Self = .init(kCTTrackingAttributeName)
    
    init(_ rawValue: CFString) {
        self.rawValue = rawValue
    }
    
}

