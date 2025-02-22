//
//  DownTeX+TeXTemplate.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//


import Foundation
import UIKit

extension DownTeX {
    /// Available font sizes.
    public enum FontSize: Hashable, Identifiable, CaseIterable {
        public var id: Self { self }
        case pt8, pt9, pt10, pt11, pt12, pt14, pt17
        /// The PointSize corresponding to the current font size.
        var pointSize: CGFloat {
            switch self {
                case .pt8: 8;   case .pt9: 9
                case .pt10: 10; case .pt11: 11
                case .pt12: 12; case .pt14: 14
                case .pt17: 17
            }
        }
    }
    //MARK: - Compile Template
    /// Layout configuration when converting Markdown text to PDF text.
    public struct ConvertConfiguration {
        /// The font size used for the main text when typesetting.
        public let fontSize: FontSize
        /// The currently used page size (in units of `pt`).
        public let pageSize: CGSize
        /// The area for layoutable text, based on the page rectangle (unit is `pt`).
        ///
        /// The rect must be the sub-rectangle of page rectangle.
        public let contentRect: CGRect
        /// The background image for all pages.
        ///
        /// Specifying this value as `nil` indicates that there is no page background.
        public let pageImage: UIImage?
        static let PageImageFileName = "PageImage.png"
        /// The title image about the article.
        public let titleImage: UIImage?
        /// The title image rectangle in `PDF` page coordinator.
        public let titleRect: CGRect?
        static let TitleImageFileName = "TitleImage.png"
        /// Indicates whether the text area is allowed to overflow the layout area.
        public let allowTextOverflow: Bool
        /// Create a layout configuration.
        ///
        /// - Parameter fontSize: The font size used for the main text when typesetting.
        /// - Parameter preferredPageSize: The currently preferred page size (in units of `pt`).
        /// - Parameter preferredLayoutRect: The area for layoutable text, based on the page rectangle (unit is `pt`).
        /// - Parameter allowTextOverflow: Indicates whether the text area is allowed to overflow the layout area.
        public init(fontSize: FontSize, pageSize: CGSize, contentRect: CGRect, allowTextOverflow: Bool, pageImage: UIImage?, titleImage: UIImage?, titleRect: CGRect?) {
            assert(CGRect(origin: .zero, size: pageSize).contains(contentRect), "[\(Self.self)][\(#function)] The page rectangle must contain text-content rectangle.")
            self.fontSize = fontSize
            self.pageSize = pageSize
            self.contentRect = contentRect
            self.allowTextOverflow = allowTextOverflow
            self.pageImage = pageImage
            self.titleImage = titleImage
            self.titleRect = titleRect
        }
    }
    
    public func convertToPDFData(markdown: String, config: ConvertConfiguration) async throws(OperationError) -> Data {
        
        if self.state == .initFailed { throw .resourceFailured }
        while self.state != .ready {
            try? await Task.sleep(for: .microseconds(10))
        }
        self.state = .running
        defer { self.state = .ready }
        return try await unsafe_convertToPDFData(markdown: markdown, config: config)
    }
    
    func unsafe_convertToPDFData(markdown: String, config: ConvertConfiguration) async throws(OperationError) -> Data {
        let latexContent = try await self.unsafe_convertToLaTeX(markdownString: markdown)
        var imagesDic = [String: UIImage]()
        if let pageImage = config.pageImage {
            imagesDic[ConvertConfiguration.PageImageFileName] = pageImage
        }
        if let titleImage = config.titleImage {
            imagesDic[ConvertConfiguration.TitleImageFileName] = titleImage
        }
        imagesDic[ConvertConfiguration.TitleImageFileName] = config.titleImage
        return try await self.unsafe_compileToPDF(
            latexString: self.template(latexContent: latexContent, config: config),
            images: imagesDic
        )
    }
    
    //MARK: - Template Content
    
    private func template(latexContent: String, config: ConvertConfiguration) -> String {
        let latexContent = latexContent
            .replacingOccurrences(of: "\\pandocbounded{\\includegraphics", with: "\\pandocbounded{\\fakeincludegraphics")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let top = config.contentRect.minY
        let bottom = config.pageSize.height - config.contentRect.maxY
        let left = config.contentRect.minX
        let right = config.pageSize.width - config.contentRect.maxX
        let titleTop = config.titleRect?.minY ?? 0.0
        return
"""
% Options for packages loaded elsewhere
\\PassOptionsToPackage{unicode}{hyperref}
\\PassOptionsToPackage{hyphens}{url}
\\documentclass[\(Int(config.fontSize.pointSize))pt,scheme=plain,fontset=none]{ctexart}
%\\usepackage[fontset=none]{ctex}
\\usepackage{extsizes, xcolor}
\\usepackage{amsmath,amssymb, mathrsfs, graphicx}
\\usepackage{geometry, fontspec}
\\usepackage{microtype}
\\usepackage{enumitem}
\\geometry{
    paperwidth=\(Int(config.pageSize.width))pt,   % Page width
    paperheight=\(Int(config.pageSize.height))pt,  % Page height
    left=\(Int(left))pt, right=\(Int(right))pt, top=\(Int(top))pt, bottom=\(Int(bottom))pt % Page Margin
}
\(config.pageImage != nil ?
"""
\\usepackage{longtable, booktabs, array, etoolbox, footnote, calc}
\\makeatletter
\\patchcmd\\longtable{\\par}{\\if@noskipsec\\mbox{}\\fi\\par}{}{}
\\makeatother
\\makesavenoteenv{longtable}
%%%%% --- Config Page Background --- %%%%%
\\AddToHook{shipout/background}{%
    \\put (0in,-\\paperheight){\\includegraphics[width=\\paperwidth,height=\\paperheight]{\(ConvertConfiguration.PageImageFileName)}}%
}
""" : String())
\\xeCJKsetup{CheckSingle,CJKmath=true}
\\setmathrm{LatinModernMath-Regular}
\\setmainfont{SFProText-Regular}
\\setmonofont{SFMono-Regular}
\\setCJKmainfont[AutoFakeSlant=true,AutoFakeBold={3}]{PingFangSC-Regular}
\\setCJKfamilyfont{songti}{PingFangSC-Regular}
\\setCJKfamilyfont{heiti}{PingFangSC-Semibold}
\\setCJKfamilyfont{kaishu}{PingFangSC-Regular}
\\newcommand{\\songti}{\\CJKfamily{songti}}
\\newcommand{\\heiti}{\\CJKfamily{heiti}}
\\newcommand{\\kaishu}{\\CJKfamily{kaishu}}
\(config.allowTextOverflow ? String() : "\\tolerance=10000")
\\setcounter{secnumdepth}{0} % remove section numbering
\\usepackage{iftex}
\\ifPDFTeX
  \\usepackage[T1]{fontenc}
  \\usepackage[utf8]{inputenc}
  \\usepackage{textcomp} % provide euro and other symbols
\\else % if luatex or xetex
  \\usepackage{unicode-math} % this also loads fontspec
%   \\defaultfontfeatures{Scale=MatchLowercase}
  \\defaultfontfeatures[\\rmfamily]{Ligatures=TeX,Scale=1}
\\fi
% \\usepackage{lmodern}
\\ifPDFTeX\\else
  % xetex/luatex font selection
\\fi
% Use upquote if available, for straight quotes in verbatim environments
\\IfFileExists{upquote.sty}{\\usepackage{upquote}}{}
\\IfFileExists{microtype.sty}{% use microtype if available
  \\usepackage[]{microtype}
  \\UseMicrotypeSet[protrusion]{basicmath} % disable protrusion for tt fonts
}{}
\\makeatletter
\\@ifundefined{KOMAClassName}{% if non-KOMA class
  \\IfFileExists{parskip.sty}{%
    \\usepackage{parskip}
  }{% else
    \\setlength{\\parindent}{0pt}
    \\setlength{\\parskip}{6pt plus 2pt minus 1pt}}
}{% if KOMA class
  \\KOMAoptions{parskip=half}}
\\makeatother
\\usepackage{color}
\\usepackage{fancyvrb, fvextra}
\\newcommand{\\VerbBar}{|}
\\newcommand{\\VERB}{\\Verb[commandchars=\\\\\\{\\}]}
\\DefineVerbatimEnvironment{Highlighting}{Verbatim}{commandchars=\\\\\\{\\}, breaklines}
% Add ',fontsize=\\small' for more characters per line
\\newenvironment{Shaded}{\\small\\vspace{0.5em}}{}
\\newcommand{\\AlertTok}[1]{\\textcolor[rgb]{1.00,0.00,0.00}{\\textbf{#1}}}
\\newcommand{\\AnnotationTok}[1]{\\textcolor[rgb]{0.38,0.63,0.69}{\\textbf{\\textit{#1}}}}
\\newcommand{\\AttributeTok}[1]{\\textcolor[rgb]{0.49,0.56,0.16}{#1}}
\\newcommand{\\BaseNTok}[1]{\\textcolor[rgb]{0.25,0.63,0.44}{#1}}
\\newcommand{\\BuiltInTok}[1]{\\textcolor[rgb]{0.00,0.50,0.00}{#1}}
\\newcommand{\\CharTok}[1]{\\textcolor[rgb]{0.25,0.44,0.63}{#1}}
\\newcommand{\\CommentTok}[1]{\\textcolor[rgb]{0.38,0.63,0.69}{\\textit{#1}}}
\\newcommand{\\CommentVarTok}[1]{\\textcolor[rgb]{0.38,0.63,0.69}{\\textbf{\\textit{#1}}}}
\\newcommand{\\ConstantTok}[1]{\\textcolor[rgb]{0.53,0.00,0.00}{#1}}
\\newcommand{\\ControlFlowTok}[1]{\\textcolor[rgb]{0.00,0.44,0.13}{\\textbf{#1}}}
\\newcommand{\\DataTypeTok}[1]{\\textcolor[rgb]{0.56,0.13,0.00}{#1}}
\\newcommand{\\DecValTok}[1]{\\textcolor[rgb]{0.25,0.63,0.44}{#1}}
\\newcommand{\\DocumentationTok}[1]{\\textcolor[rgb]{0.73,0.13,0.13}{\\textit{#1}}}
\\newcommand{\\ErrorTok}[1]{\\textcolor[rgb]{1.00,0.00,0.00}{\\textbf{#1}}}
\\newcommand{\\ExtensionTok}[1]{#1}
\\newcommand{\\FloatTok}[1]{\\textcolor[rgb]{0.25,0.63,0.44}{#1}}
\\newcommand{\\FunctionTok}[1]{\\textcolor[rgb]{0.02,0.16,0.49}{#1}}
\\newcommand{\\ImportTok}[1]{\\textcolor[rgb]{0.00,0.50,0.00}{\\textbf{#1}}}
\\newcommand{\\InformationTok}[1]{\\textcolor[rgb]{0.38,0.63,0.69}{\\textbf{\\textit{#1}}}}
\\newcommand{\\KeywordTok}[1]{\\textcolor[rgb]{0.00,0.44,0.13}{\\textbf{#1}}}
\\newcommand{\\NormalTok}[1]{#1}
\\newcommand{\\OperatorTok}[1]{\\textcolor[rgb]{0.40,0.40,0.40}{#1}}
\\newcommand{\\OtherTok}[1]{\\textcolor[rgb]{0.00,0.44,0.13}{#1}}
\\newcommand{\\PreprocessorTok}[1]{\\textcolor[rgb]{0.74,0.48,0.00}{#1}}
\\newcommand{\\RegionMarkerTok}[1]{#1}
\\newcommand{\\SpecialCharTok}[1]{\\textcolor[rgb]{0.25,0.44,0.63}{#1}}
\\newcommand{\\SpecialStringTok}[1]{\\textcolor[rgb]{0.73,0.40,0.53}{#1}}
\\newcommand{\\StringTok}[1]{\\textcolor[rgb]{0.25,0.44,0.63}{#1}}
\\newcommand{\\VariableTok}[1]{\\textcolor[rgb]{0.10,0.09,0.49}{#1}}
\\newcommand{\\VerbatimStringTok}[1]{\\textcolor[rgb]{0.25,0.44,0.63}{#1}}
\\newcommand{\\WarningTok}[1]{\\textcolor[rgb]{0.38,0.63,0.69}{\\textbf{\\textit{#1}}}}
\\makeatletter
\\newsavebox\\pandoc@box
\\newcommand{\\pandocbounded}[1]{#1}
% Set default figure placement to htbp
\\def\\fps@figure{htbp}
\\makeatother
\\setlength{\\emergencystretch}{3em} % prevent overfull lines
\\providecommand{\\tightlist}{%
  \\setlength{\\itemsep}{0pt}\\setlength{\\parskip}{0pt}}
\\usepackage{bookmark}
\\IfFileExists{xurl.sty}{\\usepackage{xurl}}{} % add URL line breaks if available
\\urlstyle{same}
\\hypersetup{
  hidelinks,
  pdfcreator={\(ChatShareApp.Name) PDF Converter},
  pdfinfo={
        Title={},
        Author={\(ChatShareApp.Name)},
        Keywords={}
  },
  pdfsubject={}
}
\\renewcommand{\\hyperref}[2][]{#2}
\\newcommand{\\fakeincludegraphics}[2][]{
\\begin{center}
    \\url{#2}  
\\end{center}
}
\\renewcommand{\\text}[1]{\\mathrm{#1}}
\\author{}
\\date{}
\\pagestyle{empty}
\\begin{document}
\(config.titleImage != nil ?
"""
\\vspace*{\\dimexpr-\(top)pt+\(Int(titleTop))pt-1em-5pt\\relax}
\\begin{center}
\\includegraphics[width=\\textwidth]{\(ConvertConfiguration.TitleImageFileName)}
\\end{center}\\nointerlineskip
""" : String()
)
\(latexContent)
\\end{document}
"""
    }
}
