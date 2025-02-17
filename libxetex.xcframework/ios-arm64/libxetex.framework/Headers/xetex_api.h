// -- **-Objective-C **---
//
//  xetex_api.h
//  XeTeX_Build
//
//  Created by 孟超 on 2024/9/2.
//

#ifndef xetex_api_h
#define xetex_api_h

#import <Foundation/Foundation.h>

/**
 Enumerations used to indicate typesetting results for the XeTeX engine.
 */
typedef NS_ENUM(NSInteger, XeTeXEngineTypesettingResult) {
    XeTeXEngineTypesettingSucceed = 0,
    XeTeXEngineTypesettingFailuredNormal = 1,
    XeTeXEngineTypesettingFailuredFatal = 3,
    XeTeXEngineTypesettingCrashedMemory = 100, /* memory allocate failured */
    XeTeXEngineTypesettingCrashedFile = 200, /* file interaction failured */
    XeTeXEngineTypesettingCrashedUnknown = 300, /* internal error occurred*/
    XeTeXEngineTypesettingCrashedFormat = 10000, /* format file lost */
};

/**
 Enumerations used to indicate INITEX results for the XeTeX engine.
 */
typedef NS_ENUM(NSInteger, XeTeXEngineInitResult) {
    XeTeXEngineInitSucceed = 0,
    XeTeXEngineInitFailuredNormal = 1,
    XeTeXEngineInitFailuredFatal = 3,
    XeTeXEngineInitCrashedMemory = 100, /* memory allocate failured */
    XeTeXEngineInitCrashedFile = 200, /* file interaction failured */
    XeTeXEngineInitCrashedUnknown = 300 /* internal error occurred*/
};

typedef NS_ENUM(NSUInteger, XeTeXEngineFormat) {
    XeTeXEngineFormatPlain = 0, /* plain-tex */
    XeTeXEngineFormatLatex = 1, /* latex */
};

NS_ASSUME_NONNULL_BEGIN

/**
 Class used to operate the XeTeX engine for compiling TeX.
 
 This class is thread-safe.
 
 - Note: All methods provided by the current engine are class methods and can be accessed on any thread. However, only one internal instance of XeTeX will be running at a time.
 */
@interface XeTeXEngine : NSObject
/**
 Set the root directory for texlive resource files.
 
 The default texlive resource directory for the engine is `$ApplicationRoot$/Library/texlive`.
  
 @param url A `URL` pointing to the TEXMF root directory of texlive resource files. The directory should include folders such as `texmf-dist`.
 @param completion The completion handler to be called when the setup is complete. If the method is called while the XeTeX engine is already compiling, the setup process will be delayed until after the compilation is finished.
 */
+ (void)setTeXLiveResourceWithDirectoryURL: (NSURL *)url onCompletion: (void (^)(void)) completion;
/**
 Retrieve the dynamic resource lookup list of the current engine.
 */
+ (nonnull NSArray <NSURL *> *)dynamicResources;
/**
 Set the list of `URL`s for directories used for dynamically searching files.

 
 @param urls A list of `URL`s pointing to folders used for executing dynamic resource searches. Each URL in the list must point to a folder. `URL`s without a hostname will be skipped automatically.
 @param completion The completion handler to be called when the setup is complete. If the method is called while the XeTeX engine is already compiling, the setup process will be delayed until after the compilation is finished.
 */
+ (void)setDynamicResourcesWithDirectoryURLs: (NSArray<NSURL*> *)urls onCompletion:(void (^__strong)(void))completion;


/**
 Set the compression options for generating PDF files.
 
 @param isUsingPDFCompression A `BOOL` value indicating whether to use PDF compression.
 */
+ (void)setUsingPDFCompression: (BOOL)isUsingPDFCompression;

/**
 Get current PDF compression options.
 */
+ (BOOL)usingPDFCompression;

/**
 Typeset the tex file.
 
 @note Before calling this method, you must ensure that the ls-R directory of texlive resource files contains the corresponding formats, or add the URL of the folder containing the format files to the dynamic resource list. Otherwise, this method will not be able to compile successfully.
 
 @param texFileURL URL of the tex file that you want to perform typesetting operations on. The caller of the current method must ensure that they have permission to access the folder containing the tex file, otherwise an error will be thrown.
 @param completion Closure called at the end of typesetting.
 */
+ (void)typesetting:(nonnull NSURL *)texFileURL format:(XeTeXEngineFormat)format onCompletion:(void (^__strong)(XeTeXEngineTypesettingResult))completion;
/**
 Executing format file generation (INITEX).
 
 @param format The desired format to be generated.
 @param completion Closure called at the end of generation. If the parameter of the closure is `nil`, it indicates that the generation has failed.
 
 */
+ (void)createFormatFileWithFormat: (XeTeXEngineFormat)format onCompletion:(void (^__strong)(NSURL *))completion;

/**
 Clear all format files cached in the current framework.
 
 @param completion Closure to be executed at the end of cleanup.
 */
+ (void)cleanAllFormatFile: (void (^__strong)(void))completion;

/**
 Attempt to cancel the current typesetting or INITEX process.
 
 This method will set the `interrupt` variable inside XeTeX to 1, attempting to cancel the running of XeTeX.
 */
+ (void)cancel;
@end

NS_ASSUME_NONNULL_END

#endif /* xetex_api_h */
