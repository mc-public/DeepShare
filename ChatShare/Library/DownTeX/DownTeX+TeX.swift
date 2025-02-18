//
//  DownTeX+TeXTemplate.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/17.
//

//import libxetex
import Foundation

extension DownTeX {
    /// Available font sizes.
    public enum FontSize {
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
    /// The relevant settings for executing LaTeX typesetting.
    private struct TypesettingConfiguration {
        /// The font size associated with this configuration.
        let fontSize: FontSize
        /// The page size associated with this configuration.
        let pageSize: CGSize
        /// Rectangles available for layout on the page.
        let layoutRect: CGRect
        
        fileprivate init(fontSize: FontSize, pageSize: CGSize, layoutRect: CGRect) {
            assert(CGRect(origin: .zero, size: pageSize).contains(layoutRect), "[\(Self.self)][\(#function)] The page rectangle must contain text-layout rectangle.")
            self.fontSize = fontSize
            self.pageSize = pageSize
            self.layoutRect = layoutRect
        }
    }
    
    //MARK: - Compile Template
    /// Layout configuration when converting Markdown text to PDF text.
    public struct ConvertConfiguration {
        /// The font size used for the main text when typesetting.
        public let fontSize: FontSize
        /// The currently preferred page size (in units of `pt`).
        ///
        /// This value is just a suggestion, and the final page size will be based on the output PDF file.
        public let preferredPageSize: CGSize
        /// The area for layoutable text, based on the page rectangle (unit is `pt`).
        ///
        /// This value is just a suggestion, and the final page size will be based on the output PDF file.
        public let preferredLayoutRect: CGRect
        /// Create a layout configuration.
        ///
        /// - Parameter fontSize: The font size used for the main text when typesetting.
        /// - Parameter preferredPageSize: The currently preferred page size (in units of `pt`).
        /// - Parameter preferredLayoutRect: The area for layoutable text, based on the page rectangle (unit is `pt`).
        public init(fontSize: FontSize, preferredPageSize: CGSize, preferredLayoutRect: CGRect) {
            assert(CGRect(origin: .zero, size: preferredPageSize).contains(preferredLayoutRect), "[\(Self.self)][\(#function)] The page rectangle must contain text-layout rectangle.")
            self.fontSize = fontSize
            self.preferredPageSize = preferredPageSize
            self.preferredLayoutRect = preferredLayoutRect
        }
    }
    
    func convertToPDFData(markdown: String, template: QATemplateModel, config: ConvertConfiguration) async throws(OperationError) -> Data {
        
        if self.state == .initFailed { throw .resourceFailured }
        while self.state != .ready {
            try? await Task.sleep(for: .microseconds(10))
        }
        self.state = .running
        defer { self.state = .ready }
        return try await unsafe_convertToPDFData(markdown: markdown, template: template, config: config)
    }
    
    func unsafe_convertToPDFData(markdown: String, template: QATemplateModel, config: ConvertConfiguration) async throws(OperationError) -> Data {
        let latexContent = try await self.unsafe_convertToLaTeX(markdownString: markdown)
        guard let templateResult = QATemplateManager.current.renderingResult(for: template, preferredSize: config.preferredPageSize) else {
            fatalError("[\(Self.self)][\(#function)] Valid preferred size: \(config.preferredPageSize). Please check input parameters.")
        }
        let pageImage = await templateResult.totalImage()
        let newConfig = TypesettingConfiguration(
            fontSize: config.fontSize,
            pageSize: pageImage.size,
            layoutRect: templateResult.textRect.intersection(
                CGRect(origin: .zero, size: pageImage.size)
            )
        )
        return try await self.unsafe_compileToPDF(latexString: self.template(markdownContent: latexContent, config: newConfig))
    }
    
    //MARK: - Template Content
    
    private func template(markdownContent: String, config: TypesettingConfiguration) -> String {
        let top = config.layoutRect.minY
        let bottom = config.pageSize.height - config.layoutRect.maxY
        let left = config.layoutRect.minX
        let right = config.pageSize.width - config.layoutRect.maxX
        return
"""
% Options for packages loaded elsewhere
\\PassOptionsToPackage{unicode}{hyperref}
\\PassOptionsToPackage{hyphens}{url}
\\documentclass[\(config.fontSize.pointSize)pt]{extarticle}
\\usepackage[fontset=none]{ctex}
\\usepackage{xcolor, extsizes}
\\usepackage{amsmath,amssymb, mathrsfs}
\\usepackage{geometry, fontspec}
\\usepackage{microtype}
\\usepackage{enumitem}
\\geometry{
    paperwidth=\(config.pageSize.width)pt,   % Page width
    paperheight=\(config.pageSize.height)pt,  % Page height
    left=\(left)pt, right=\(right)pt, top=\(top)pt, bottom=\(bottom)pt % Page Margin
}
\\xeCJKsetup{CheckSingle,CJKmath=true}

\\setmathrm{LatinModernMath-Regular}
\\setmainfont{SFProDisplay-Regular}
% \\setsansfont{SFPro-Regular}
\\setmonofont{SFMono-Regular}
\\setCJKmainfont[AutoFakeSlant=true,BoldFont=.PingFang-SC-Semibold]{PingFang-SC-Regular}
\\setCJKfamilyfont{songti}{PingFang-SC-Regular}
\\setCJKfamilyfont{heiti}{PingFang-SC-Regular}
\\setCJKfamilyfont{kaishu}{PingFang-SC-Regular}
\\newcommand{\\songti}{\\CJKfamily{songti}}
\\newcommand{\\heiti}{\\CJKfamily{heiti}}
\\newcommand{\\kaishu}{\\CJKfamily{kaishu}}

\\tolerance=10000

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
  pdfcreator={SwiftMarkdown}
}
\\renewcommand{\\hyperref}[2][]{#2}
\\newcommand{\\includegraphics}[2][]{
\\begin{center}
    \\url{#2}  
\\end{center}
}
\\renewcommand{\\text}[1]{\\mathrm{#1}}
\\author{}
\\date{}
\\begin{document}
\(markdownContent)
\\end{document}
"""
    }
}
