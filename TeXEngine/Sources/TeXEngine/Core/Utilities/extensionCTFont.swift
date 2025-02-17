//
//  extensionCTFont.swift
//
//
//  Created by 孟超 on 2023/7/27.
//

import CoreText
import Foundation


extension CTFont {
    
    /// Returns the type identifier for Core Text font references.
    static var TypeID: CFTypeID {
        CTFontGetTypeID()
    }
    
    /// Returns the `URL` of current font.
    var url: URL? {
        CTFontCopyAttribute(self, kCTFontURLAttribute) as? URL
    }
    /// Returns the family name of current font.
    var familyName: String {
        CTFontCopyFamilyName(self) as String
    }
    /// Returns the PostScript name of current font.
    var postScriptName: String {
        CTFontCopyPostScriptName(self) as String
    }
    /// Returns the full name of current font.
    var fullName: String {
        CTFontCopyFullName(self) as String
    }
    /// Returns the display name of current font.
    var displayName: String {
        CTFontCopyDisplayName(self) as String
    }
    /// Returns the point size of the given font.
    var size: CGFloat {
        CTFontGetSize(self)
    }
    /// Returns the transformation matrix of the given font.
    var matrix: CGAffineTransform {
        CTFontGetMatrix(self)
    }
    /// Returns the scaled font-ascent metric of the given font.
    var ascent: CGFloat {
        CTFontGetAscent(self)
    }
    /// Returns the scaled font-descent metric of the given font.
    var descent: CGFloat {
        CTFontGetDescent(self)
    }
    /// Returns the scaled font-leading metric of the given font.
    var leading: CGFloat {
        CTFontGetLeading(self)
    }
    /// Returns the units-per-em metric of the given font.
    var unitsPerEm: UInt32 {
        CTFontGetUnitsPerEm(self)
    }
    /// Returns the number of glyphs of the given font.
    var glyphCount: CFIndex {
        CTFontGetGlyphCount(self)
    }
    /// Returns the scaled bounding box of the given font.
    var boundingBox: CGRect {
        CTFontGetBoundingBox(self)
    }
    /// Returns the scaled underline position of the given font.
    var underlinePosition: CGFloat {
        CTFontGetUnderlinePosition(self)
    }
    /// Returns the scaled underline-thickness metric of the given font.
    var underlineThickness: CGFloat {
        CTFontGetUnderlineThickness(self)
    }
    /// Returns the slant angle of the given font.
    var slantAngel: CGFloat {
        CTFontGetSlantAngle(self)
    }
    /// Returns the cap-height metric of the given font.
    var capHeight: CGFloat {
        CTFontGetCapHeight(self)
    }
    /// Returns the x-height metric of the given font.
    var xHeight: CGFloat {
        CTFontGetXHeight(self)
    }
    
    /// Returns the symbolic traits of the given font.
    var symbolicTraits: CTFontSymbolicTraits {
        CTFontGetSymbolicTraits(self)
    }
    /// Returns the Unicode character set of the font.
    var characterSet: CharacterSet {
        CTFontCopyCharacterSet(self) as CharacterSet
    }
    /// Returns the best string encoding for legacy format support.
    var stringEncoding: CFStringEncoding {
        CTFontGetStringEncoding(self)
    }
    
    /// Returns an array of languages supported by the font.
    ///
    /// The format of the language identifier conforms to the RFC 3066bis standard.
    var supportedLanguages: [String] {
        CTFontCopySupportedLanguages(self) as? [String] ?? []
    }
    
    /// Returns the descriptor of current font.
    var descriptor: CTFontDescriptor {
        CTFontCopyFontDescriptor(self)
    }
    
    /// Returns the requested name of the given font.
    ///
    /// - Parameter nameKey:
    /// The name specifier. See ``Name Specifier Constants`` for possible values.
    /// - Returns: The requested name for the font, or `nil` if the font does not have an entry for the requested name. The Unicode version of the name is preferred, otherwise the first available version is returned.
    func copyName(_ nameKey: NameKey) -> String? {
        return CTFontCopyName(self, nameKey.rawValue) as String?
    }
    
    /// Returns a localized name for the given font.
    ///
    /// The name is localized based on the user's global language preference precedence. That is, the user’s language preference is a list of languages in order of precedence. So, for example, if the list had Japanese and English, in that order, then a font that did not have Japanese name strings but had English strings would return the English strings.
    ///
    /// - Parameter nameKey:
    /// The name specifier. See `Name Specifier Constants` for possible values.
    ///
    /// - Returns: A specific localized name from the font or `nil` if the font does not have an entry for the requested name key.
    func copyLocalizedName(_ nameKey: NameKey) -> (name: String?, language: String?) {
        let languageValue = String() as CFString
        var unmanagedLanguage: Unmanaged<CFString>? = Unmanaged.passRetained(languageValue)
        return (CTFontCopyLocalizedName(self, nameKey.rawValue, &unmanagedLanguage) as String?, unmanagedLanguage?.takeRetainedValue() as String?)
        
    }
    
    /// Returns the value associated with an arbitrary attribute of current font.
    ///
    /// Refer to the attribute definitions documentation for information as to how each attribute is packaged as a `CFType`.
    /// - Parameter font:
    /// The font reference.
    /// - Parameter attribute:
    /// The requested attribute.
    /// - Returns: A **retained reference** to an arbitrary attribute or `nil` if the requested attribute is not present.
    func copyAttribute(_ attribute: Attribute) -> CFTypeRef? {
        return CTFontCopyAttribute(self, attribute.rawValue)
    }
    
    /// Returns a new font reference that best matches the given font descriptor.
    ///
    /// The `size` parameters override any specified in the font descriptor, unless they are unspecified (`0.0` for `size` and `nil` for `options`). A best match font is always returned, and default values are used for any unspecified.
    ///
    /// - Parameter descriptor:
    /// A font descriptor containing attributes that specify the requested font.
    /// - Parameter size:
    /// The point size for the font reference. If `0.0` is specified, the default font size of 12.0 is used. This parameter is optional.
    /// - Parameter options:
    /// Options flags. See `CTFontOptions` for values. This parameter is optional.
    /// - Returns: A `CTFont` that best matches the attributes provided with the font descriptor.
    static func make(from descriptor: CTFontDescriptor, size: CGFloat = 0.0, options: CTFontOptions? = nil) -> CTFont {
        if let options = options {
            return CTFontCreateWithFontDescriptorAndOptions(descriptor, size, nil, options)
        }
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }
    
    /// Returns a new font reference for the given name.
    ///
    /// The `name` parameter is the only required parameter, and default values are used for unspecified parameters (`0.0` for size and `nil` for `options`). If all parameters cannot be matched identically, a best match is found.
    ///
    /// - Parameter name:
    /// The font name for which you wish to create a new font reference. A valid PostScript name is preferred, although other font name types are matched in a fallback manner.
    /// - Parameter size:
    /// The point size for the font reference. If `0.0` is specified, the default font size of 12.0 is used. This parameter is optional.
    /// - Parameter options:
    /// Options flags. See `CTFontOptions` for values. This parameter is optional.
    ///
    /// - Returns Returns a `CTFont` that best matches the name provided with size.
    static func make(from fontname: String, size: CGFloat = 0.0, options: CTFontOptions? = nil) -> CTFont {
        if let options = options {
            return CTFontCreateWithNameAndOptions(fontname as CFString, size, nil, options)
        }
        return CTFontCreateWithName(fontname as CFString, size, nil)
    }
    
    
    
    
}


extension CTFontDescriptor {
    /**
     Creates a new font descriptor reference from a dictionary of attributes.

     The provided attribute dictionary can contain arbitrary attributes that are preserved; however, unrecognized attributes are ignored on font creation and may not be preserved over the round trip from descriptor to font and back to descriptor.
     
     - Parameter attributes:
        A dictionary containing arbitrary attributes.
     
     - Returns: A new font descriptor with the attributes specified.
     */
    static func make(attributes: [CFString : AnyObject]) -> CTFontDescriptor {
        CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
    }
    
    /**
     Creates a copy of the font descriptor in the specified family based on the traits of the original.
     
     - Parameters:
        - original:
            The original font descriptor.
        - family:
            The name of the desired family.
     - Returns:
        A new font descriptor with the original traits in the given family, or `nil` if no matching font descriptor is found in the system.
     */
    static func make(original: CTFontDescriptor, family: String) -> CTFontDescriptor? {
        CTFontDescriptorCreateCopyWithFamily(original, family as CFString)
    }
    
    /**
     Creates a font descriptor representing the font in the supplied data.

     If the data contains a font collection (`TTC` or `OTC`), only the first font in the collection will be returned. Use `CTFontManagerCreateFontDescriptorsFromData(_:)` in that case.
     
     > The font descriptor returned by this function is not available through font descriptor matching. As a result, you can’t directly look for the font by name with functions like `CTFontCreateWithName(_:_:_:)`. If you wish to make the font available for name matching, use `CTFontManagerRegisterFontURLs(_:_:_:_:)` instead.
     
     - Parameter data:
        The font data.
     
     - Returns:
        A font descriptor created from the data or `nil` if it is not a valid font.
     */
    static func make(data: Data) -> CTFontDescriptor? {
        CTFontManagerCreateFontDescriptorFromData(data as CFData)
    }
    
    /**
     Creates an array of font descriptors for the fonts in the supplied data.
     
     This is the preferred function when the data contains a font collection (`TTC` or `OTC`). This function returns an empty array in the event of invalid or unsupported font data.
     
     > The font descriptors are not available through font descriptor matching. As a result, you can’t directly look for the fonts by name with functions like `CTFontCreateWithName(_:_:_:)`. If you wish to make the font available for name matching, use `CTFontManagerRegisterFontURLs(_:_:_:_:)` instead.
     
     - Parameter data:
        The font data.
     
     - Returns:
        An array of font descriptors.
     */
    static func makeArray(data: Data) -> [CTFontDescriptor] {
        (CTFontManagerCreateFontDescriptorsFromData(data as CFData) as? [CTFontDescriptor]) ?? []
    }
    
    
    /**
     Returns an array of font descriptors representing each of the fonts in the specified `URL`.

     - Parameters:
        - fileURL:
            A file system `URL` referencing a valid font file.
     - Returns:
        This function returns an array of `CTFontDescriptor` objects.
     */
    static func makeArray(fileURL: URL) -> [CTFontDescriptor] {
        (CTFontManagerCreateFontDescriptorsFromURL(fileURL as CFURL) as? [CTFontDescriptor]) ?? []
    }
    
    
    /**
     Returns the single preferred matching font descriptor based on current descriptor and system precedence.
     
     The original descriptor may be returned in normalized form. The caller is responsible for releasing the result. In the context of font descriptors, *normalized* infers that the input values were matched up with actual existing fonts, and the descriptors for those existing fonts are the returned normalized descriptors.
     
     - Parameter mandatoryAttributes:
        A set of attribute keys which must be identically matched in any returned font descriptors. May be `nil`.
     - Returns:
        A normalized font descriptor matching the attributes present in descriptor.

     */
    func matchingFontDescriptor(mandatoryAttributes: Set<CTFont.Attribute>?) -> CTFontDescriptor? {
        guard let set = mandatoryAttributes else {
            return CTFontDescriptorCreateMatchingFontDescriptor(self, nil)
        }
        let newSet = Set(set.map { $0.rawValue })
        return CTFontDescriptorCreateMatchingFontDescriptor(self, newSet as CFSet)
        
    }
    
    /**
        Returns an array of normalized font descriptors matching current descriptor.
        
        If `descriptor` itself is normalized, then the array will contain only one item: the original descriptor. In the context of font descriptors, *normalized* infers that the input values were matched up with actual existing fonts, and the descriptors for those existing fonts are the returned normalized descriptors.
     
        - Parameter mandatoryAttributes:
            A set of attribute keys which must be identically matched in any returned font descriptors. May be `nil`.
        - Returns:
            A array of normalized font descriptors matching the attributes present in descriptor.
     */
    func matchingFontDescriptors(mandatoryAttributes: Set<CTFont.Attribute>?) -> [CTFontDescriptor] {
        guard let set = mandatoryAttributes else {
            return CTFontDescriptorCreateMatchingFontDescriptors(self, nil) as? [CTFontDescriptor] ?? []
        }
        let newSet = Set(set.map { $0.rawValue })
        return CTFontDescriptorCreateMatchingFontDescriptors(self, newSet as CFSet) as? [CTFontDescriptor] ?? []
    }
    
    /// Returns the value associated with an arbitrary attribute.
    ///
    /// Refer to Accessing Font Attributes for documentation explaining how each attribute is packaged as a `CFType` object.
    ///
    /// - Parameters:
    ///     - descriptor:
    ///         The font descriptor.
    ///     - attribute:
    ///         The requested attribute.
    ///
    /// - Returns:
    ///     An arbitrary attribute, or `nil` if the requested attribute is not present.
    func copyAttribute(_ attribute: CTFont.Attribute) -> AnyObject? {
        return CTFontDescriptorCopyAttribute(self, attribute.rawValue)
    }
    
    /// Returns a localized value for the requested attribute, if available.
    ///
    /// This function passes back the matched language in language. If localization is not possible for the attribute, the behavior matches the value returned from `CTFontDescriptorCopyAttribute(_:_:)`. Generally, localization of attributes is applicable to name attributes of only a normalized font descriptor.
    ///
    ///
    func copyLocalizedAttribute(_ attribute: CTFont.Attribute) -> (value: AnyObject?, language: String?) {
        var unmanagedLanguage: Unmanaged<CFString>? = nil
        return (CTFontDescriptorCopyLocalizedAttribute(self, attribute.rawValue, &unmanagedLanguage), unmanagedLanguage?.takeUnretainedValue() as String?)
        
    }
    
    
    /// Check if the URL corresponding to the font description can be accessed.
    var isURLReachable: Bool {
        guard let url = self.copyAttribute(.url) as? URL else {
            return false
        }
        let result = (try? url.checkResourceIsReachable()) ?? false
        return result
    }
    
}

extension CTFontCollection {
    
    /// Creates an array of font descriptors that match current collection.
    ///
    /// - Parameter options:
    /// The options dictionary. If passing in `nil`, the method will uses the options specified during the collection's creation.
    ///
    /// - Returns: An array of `CTFontDescriptor` objects that match the collection definition, or `nil` if there are none.
    func matchingFontDescriptor(options: [CFString: AnyObject]?) -> [CTFontDescriptor]? {
        return CTFontCollectionCreateMatchingFontDescriptorsWithOptions(self, options as CFDictionary?) as? [CTFontDescriptor]
    }
    
    
    /// Returns the array of matching font descriptors sorted with the callback function.
    ///
    /// - Parameter sortCallback:
    /// The sorting callback function that defines the sort order.
    /// - Parameter refCon:
    /// Pointer to client data define context for the callback.
    ///
    /// - Returns: An array of font descriptors matching the criteria of the collection sorted by the results of the sorting callback function.
    func matchingFontDescriptor(sort sortCallback: CTFontCollectionSortDescriptorsCallback? = nil, refCon: UnsafeMutableRawPointer? = nil) -> [CTFontDescriptor]? {
        return CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(self, sortCallback, refCon) as? [CTFontDescriptor]
    }
    
    /**
     Returns a new font collection based on the given array of font descriptors.
     
     The contents of the returned collection are defined by matching the provided descriptors against all available font descriptors.
     
     - Parameter descriptors:
        An array of font descriptors.
     - Parameter options:
        The options dictionary. For possible values, see `Constants`.
     - Returns:
        A new font collection based on the provided font descriptors.
     */
    static func make(from fontDescriptors: [CTFontDescriptor]?, options: [CFString: AnyObject]? = nil) -> CTFontCollection {
        CTFontCollectionCreateWithFontDescriptors(fontDescriptors as CFArray?, options as CFDictionary?)
    }
    
    /**
     Returns a copy which is augmented with the given new font descriptors of current collection.
     
     The new font descriptors are merged with the existing descriptors to create a single set.
     
     - Parameters:
        - descriptors:
            An array of font descriptors to augment those of current collection.
        - options:
            The options dictionary. For possible values, see `Constants`.
     
     - Returns:
        A copy of the original font collection augmented by the new font descriptors and options.
     */
    func copy(with fontDescriptors: [CTFontDescriptor]?, options: [CFString: AnyObject]? = nil) -> CTFontCollection {
        CTFontCollectionCreateCopyWithFontDescriptors(self, fontDescriptors as CFArray?, options as CFDictionary?)
    }
    
    /// Returns the type identifier for Core Text font collection references.
    ///
    static var TypeID: CFTypeID {
        CTFontCollectionGetTypeID()
    }
    
}


class CTFontManager {
    /// The shared font manager object for the process.
    nonisolated(unsafe) static let share: CTFontManager = .init()
    
    private init() {}
    
    /**
     Returns a new font collection containing all available fonts.
     
     - Parameter options:
        The options dictionary. For possible values, see `Constants` in `CoreText` Framework.
     - Returns:
        A new collection containing all fonts available to the current application.
     */
    func availableFontCollection(attributes: [CFString: AnyObject]? = nil) -> CTFontCollection {
        CTFontCollectionCreateFromAvailableFonts(attributes as CFDictionary?)
    }
    
    /// Returns an array of visible font family names sorted for user interface display.
    var availableFontFamilyNames: [String] {
        let array = CTFontManagerCopyAvailableFontFamilyNames()
        return array as? [String] ?? []
    }
    
    /// Returns an array of unique PostScript font names for the fonts.
    var availablePostScriptNames: [String] {
        let array = CTFontManagerCopyAvailablePostScriptNames()
        return array as? [String] ?? []
    }
    
    /// Resolves font descriptors specified on input.
    ///
    /// On iOS, fonts registered by font provider apps in the `CTFontManagerScope.persistent` scope aren’t automatically available to other apps. Other apps must call this function to make the fonts available for font descriptor matching.
    ///
    /// On iOS, if the font descriptors can't be found, the system presents the user with a dialog that indicates which fonts couldn't be resolved. The system may provide the user with a way to resolve the missing fonts, if the font manager has a way to enable them.
    ///
    /// - Parameter fontDescriptors:
    /// An array of font descriptors to make available to the process. The keys for describing the fonts may be a combination of `kCTFontNameAttribute`, `kCTFontFamilyNameAttribute`, or `kCTFontRegistrationUserInfoAttribute`.
    /// - Parameter completionHandler:
    /// A block called after the request operation completes. This block takes a `unresolvedFontDescriptors` parameter which is an array of descriptors that couldn't be resolved or found. The array can be empty if all descriptors resolved.
    func requestFonts(fontDescriptors: [CTFontDescriptor], completionHandler: @escaping ([CTFontDescriptor]) -> Void) {
        let handler = { (unsolvedDescriptors: CFArray) in
            completionHandler(unsolvedDescriptors as? [CTFontDescriptor] ?? [])
        }
        CTFontManagerRequestFonts(fontDescriptors as CFArray, handler)
    }
    
    
    /// Registers fonts from the specified font URLs with the font manager.
    ///
    /// Registered fonts are discoverable through font descriptor matching in the calling process.
    ///
    /// - Parameter fontURLs:
    /// A file `URL` for the fonts or collections (in `TTC` or `OTC` format) to register. After registering fonts from a file, don't move or rename the file.
    ///
    /// - Parameter scope:
    /// A scope constant that defines the availability and lifetime of the registration. If you specify `CTFontManagerScope.persistent` when you register fonts on iOS, those fonts aren’t automatically available to other processes. Other processes can call `CTFontManagerRequestFonts(_:_:)` to get access to those fonts. See `CTFontManagerScope` for more details.
    ///
    /// - Parameter enableMatch:
    ///  Boolean value that indicates whether the font derived from the `URL` should be enabled for font descriptor matching and discoverable through `CTFontManagerRequestFonts(_:_:)`.
    ///
    /// - Parameter registrationHandler:
    /// A block called as errors arise or upon completion.
    /// The block’s errors parameter is an array of `CFError` references; an empty array indicates no errors. Each error reference contains a `CFArray` of font descriptors corresponding to `kCTFontManagerErrorFontURLsKey`. These URLs represent the font files causing the error and failing to register successfully.
    /// This block may be called multiple times during the registration process. The done parameter becomes `true` when the registration process completes. Return `false` from the block to stop the registration operation, like after receiving an error.
    ///
    func registerFont(for fontURLs: [URL], in scope: CTFontManagerScope, _ enableMatch: Bool = true, _ registrationHandler: (([CFError], Bool) -> Bool)? = nil) {
        guard let registrationHandler = registrationHandler else {
            CTFontManagerRegisterFontURLs(fontURLs as CFArray, scope, enableMatch, nil)
            return
        }
        CTFontManagerRegisterFontURLs(fontURLs as CFArray, scope, enableMatch) { cfErrorArray, done in
            return registrationHandler(cfErrorArray as? [CFError] ?? [], done)
        }
    }
    
    /// Registers the specified graphics font with the font manager.
    ///
    /// Registered fonts are discoverable through font descriptor matching. Any attempt to register a font that is either already registered or contains the same Postscript of an already registered font will fail. This behavior is useful for fonts that may be embedded in documents or constructed in memory. A graphics font is obtained by calling `init(_:)`. Fonts that are backed by files should be registered using `CTFontManagerRegisterFontsForURL(_:_:_:)`.
    ///
    /// > It may thorw a error which, in case of failed registration, contains error information.
    ///
    /// - Parameters:
    ///      - font: The graphics font to be registered.
    ///
    func registerFont(for font: CGFont) throws {
        guard let error = CFErrorCreate(nil, kCFErrorDomainPOSIX, 0, nil) else {
            return
        }
        var unmanagedError: Unmanaged<CFError>? = Unmanaged.passRetained(error)
        CTFontManagerRegisterGraphicsFont(font, &unmanagedError)
        if let unmanagedError = unmanagedError {
            throw unmanagedError.takeRetainedValue()
        }
    }
    
    /// Registers fonts from the specified font URL with the Font Manager. Registered fonts are discoverable through font descriptor matching.
    ///
    /// > It may thorw a error which, in case of failed registration, contains error information.
    ///
    ///  - Parameter fontURL:
    /// The font `URL`.
    ///
    ///  - Parameter scope:
    /// Scope constant defining the availability and lifetime of the registration. See `CTFontManagerScope` for values to pass for this parameter.
    func registerFont(for fontURL: URL, scope: CTFontManagerScope) throws {
        guard let error = CFErrorCreate(nil, kCFErrorDomainPOSIX, 0, nil) else {
            return
        }
        var unmanagedError: Unmanaged<CFError>? = Unmanaged.passRetained(error)
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, scope, &unmanagedError)
        if let unmanagedError = unmanagedError {
            throw unmanagedError.takeRetainedValue()
        }
    }
    
    /// Registers font descriptors with the font manager.
    ///
    /// Registered fonts are discoverable through font descriptor matching in the calling process.
    /// Fonts descriptors registered in a disabled state (the `enableMatch` parameter set to `false`) aren't immediately available for descriptor matching, but the font manager knows the descriptors can be made available if necessary. You can enable these descriptors by calling this function again with the enabled parameter set to `true`. This operation may fail if there's another registered and enabled font with the same PostScript name.
    ///
    /// - Parameter fontDescriptors:
    ///     An array of font descriptors to register. The font descriptor keys for registration are `kCTFontURLAttribute`, `kCTFontNameAttribute`, `kCTFontFamilyNameAttribute`, or `kCTFontRegistrationUserInfoAttribute`.
    ///
    /// - Parameter scope:
    ///     A scope constant that defines the availability and lifetime of the registration. If you specify `CTFontManagerScope.persistent` when you register fonts on iOS, those fonts aren't automatically available to other processes. Other processes can call `CTFontManagerRequestFonts(_:_:)` to get access to those fonts. See `CTFontManagerScope` for more details.
    ///
    /// - Parameter enableMatch:
    ///     A Boolean value that indicates whether the font descriptors should be enabled for font descriptor matching and discoverable though `CTFontManagerRequestFonts(_:_:)`.
    ///
    /// - Parameter registrationHandler:
    ///     A block called as errors arise or upon completion.
    ///
    ///     The block's first parameter is an array of `CFError`; an empty array indicates no errors. Each error reference contains a `CFArray` of font descriptors corresponding to `kCTFontManagerErrorFontDescriptorsKey`. These represent the font descriptors causing the error and failing to register successfully.
    ///
    ///     This block may be called multiple times during the registration process. The second parameter becomes `true` when the registration process completes. Return `false` from the block to stop the registration operation, like after receiving an error.
    func registerFont(for fontDescriptors: [CTFontDescriptor], in scope: CTFontManagerScope, _ enableMatch: Bool = true, _ registrationHandler: (([CFError], Bool) -> Bool)? = nil) {
        guard let registrationHandler = registrationHandler else {
            CTFontManagerRegisterFontDescriptors(fontDescriptors as CFArray, scope, enableMatch, nil)
            return
        }
        CTFontManagerRegisterFontDescriptors(fontDescriptors as CFArray, scope, enableMatch) { cfErrorArray, done in
            return registrationHandler(cfErrorArray as? [CFError] ?? [], done)
        }
    }
    
    /**
     Registers named font assets in the specified bundle with the font manager.
     
     Registered fonts are discoverable through font descriptor matching in the calling process.
     
     Calling this function extracts the font assets from the asset catalog and registers them. You must make this call after the completion handler of either `beginAccessingResources(completionHandler:):` or `conditionallyBeginAccessingResources(completionHandler:)` is called successfully.
     Name the assets using PostScript names for individual faces, or family names for variable or collection fonts. You can use the same names to unregister the fonts with `CTFontManagerUnregisterFontDescriptors(_:_:_:)`.

     - Parameter fontAssetNames:
        An array of font name assets in the asset catalog.
     - Parameter bundle
        A bundle that contains the asset catalog. Passing `nil` resolves to the main bundle.
     - Parameter scope
        A scope constant that defines the availability and lifetime of the registration. On iOS, the only supported scope is `CTFontManagerScope.persistent`, which means the fonts aren’t automatically available to other processes. Other processes can call `CTFontManagerRequestFonts(_:_:)` to get access to the fonts. See `CTFontManagerScope` for more details.
     - Parameter enableMatch
        A Boolean value that indicates whether the font assets should be enabled for font descriptor matching and discoverable through `CTFontManagerRequestFonts(_:_:)`.
     - Parameter registrationHandler
        A block called as errors arise or upon completion.
     
        The block’s first parameter is an array of `CFError`; an empty array indicates no errors. Each error reference contains a `CFArray` of font asset names corresponding to `kCTFontManagerErrorFontAssetNameKey`. These represent the font asset names causing the error and failing to register successfully.
     
        This block may be called multiple times during the registration process. The second parameter becomes `true` when the registration process completes. Return `false` from the block to stop the registration operation, like after receiving an error.
     
     */
    func registerFont(fontAssetNames: [String], bundle: CFBundle? = nil, in scope: CTFontManagerScope, _ enableMatch: Bool = true, _ registrationHandler: (([CFError], Bool) -> Bool)? = nil) {
        guard let registrationHandler = registrationHandler else {
            CTFontManagerRegisterFontsWithAssetNames(fontAssetNames as CFArray, bundle, scope, enableMatch, nil)
            return
        }
        CTFontManagerRegisterFontsWithAssetNames(fontAssetNames as CFArray, bundle, scope, enableMatch) { cfErrorArray, done in
            return registrationHandler(cfErrorArray as? [CFError] ?? [], done)
        }
    }
    
    /**
     Retrieves the font descriptors that were registered with the font manager.
     
     - Parameter scope:
        A scope constant that defines the availability and lifetime of the registration. If you specify `CTFontManagerScope.persistent`, only macOS can return fonts registered by any process. Other platforms can only return font descriptors registered by the app's process. See `CTFontManagerScope` for more details.
     - Parameter enableMatch:
        A Boolean value that indicates whether to return registered font descriptors that are enabled or disabled.
     - Returns:
        An array of font descriptors registered by the app. The array may be empty if nothing is registered.
     */
    func registeredFontDescriptors(in scope: CTFontManagerScope, _ enableMatch: Bool = true) -> [CTFontDescriptor] {
        return CTFontManagerCopyRegisteredFontDescriptors(scope, enableMatch) as? [CTFontDescriptor] ?? []
    }
    
    
    /**
     Unregisters fonts from the specified font URLs with the font manager.
     
     Unregistered fonts don't participate in font descriptor matching.
     
     > On iOS, you can only use this function to unregister fonts that you registered using `CTFontManager.registerFontsForURL(_:_:_:)` or `CTFontManager.registerFontsForURLs(_:_:_:)`.
     
     - Parameter fontURLs:
        An array of font URLs.
     - Parameter scope:
        A scope constant that defines the availability and lifetime of the registration. This value should match the scope the fonts are registered in. See `CTFontManagerScope` for more details.
     - Parameter registrationHandler:
        A block called as errors arise or upon completion.
     
        The block’s first parameter contains an array of `CFError`; an empty array indicates no errors unregistering the files. Each error reference contains a `CFArray` of font URLs corresponding to `kCTFontManagerErrorFontURLsKey`. These URLs represent the font files causing the error and failing to unregister successfully.
     
        This block may be called multiple times during the unregistration process. The done parameter becomes `true` when the unregistration process completes. Return `false` from the block to stop the unregistration operation, like after receiving an error.
     
     */
    func unRegister(for fontURLs: [URL], in scope: CTFontManagerScope, _ registrationHandler: (([CFError], Bool) -> Bool)? = nil) {
        guard let registrationHandler = registrationHandler else {
            CTFontManagerUnregisterFontURLs(fontURLs as CFArray, scope, nil)
            return
        }
        CTFontManagerUnregisterFontURLs(fontURLs as CFArray, scope) { array, done in
            return registrationHandler(array as? [CFError] ?? [], done)
        }
    }
    
    /**
     Unregisters fonts from the specified font `URL` with the Font Manager. Unregistered fonts are no longer discoverable through font descriptor matching.
     
     - Parameters:
        - fontURL:
            The font URL.
        - scope:
            Scope constant defining the availability and lifetime of the registration. See `CTFontManagerScope` for values to pass for this parameter.
     - Returns: A `CFError?` object which, in case of failed registration, contains error information.
     
     */
    func unRegister(for fontURL: URL, in scope: CTFontManagerScope) throws {
        var unmanagedError: Unmanaged<CFError>? = nil
        CTFontManagerUnregisterFontsForURL(fontURL as CFURL, scope, &unmanagedError)
        if let unmanagedError = unmanagedError {
            throw unmanagedError.takeUnretainedValue()
        }
        
    }
    
    /**
     Unregisters the specified graphics font with the font manager.
     
     Unregistered fonts are no longer discoverable through font descriptor matching. Fonts that are backed by files should be unregistered using `CTFontManagerUnregisterFontsForURL(_:_:_:)`.
     
     > It may throw a `CFError` object which, in case of failed registration, contains error information.

     
     - Parameter font:
        The graphics font to be unregistered.
     
     */
    func unRegister(for font: CGFont) throws {
        guard let error = CFErrorCreate(nil, kCFErrorDomainPOSIX, 0, nil) else {
            return
        }
        var unmanagedError: Unmanaged<CFError>? = Unmanaged.passRetained(error)
        CTFontManagerUnregisterGraphicsFont(font, &unmanagedError)
        if let unmanagedError = unmanagedError {
            throw unmanagedError.takeRetainedValue()
        }
    }
    
    
    /**
     Unregisters font descriptors with the font manager.
     
     Unregistered fonts don't participate in font descriptor matching.

     - Parameters:
        - fontDescriptors:
            An array of font descriptors to unregister.
        - scope:
            A scope constant that defines the availability and lifetime of the registration. See `CTFontManagerScope` for more details.
        - registrationHandler:
            A block called as errors arise or upon completion.
     
            The block’s first parameter contains an array of `CFError`; an empty array indicates no errors unregistering the font descriptors. Each error reference contains a `CFArray` of font descriptors corresponding to `kCTFontManagerErrorFontDescriptorsKey`. These represent the font descriptors causing the error and failing to unregister successfully.
     
            This block may be called multiple times during the unregistration process. The second parameter becomes `true` when the unregistration process completes. Return `false` from the block to stop the unregistration operation, like after receiving an error.
     */
    func unRegister(for fontDescriptors: [CTFontDescriptor], in scope: CTFontManagerScope, _ registrationHandler: (([CFError], Bool) -> Bool)? = nil) {
        guard let registrationHandler = registrationHandler else {
            CTFontManagerUnregisterFontDescriptors(fontDescriptors as CFArray, scope, nil)
            return
        }
        CTFontManagerUnregisterFontDescriptors(fontDescriptors as CFArray, scope) { array, done in
            return registrationHandler(array as? [CFError] ?? [], done)
        }
    }
}



