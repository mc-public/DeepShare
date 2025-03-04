# TeXEngine

![](https://img.shields.io/badge/Platform_Compatibility-iOS16.0+-blue)
![](https://img.shields.io/badge/Swift_Compatibility-5.8-red)

TeXEngine 是一个 Swift 包，为开发者在 iOS 设备上使用 TeX Live 提供的 TeX 引擎提供了可能。目前，此框架中附带了 XeTeX 引擎与 pdfTeX 引擎的修改版本。

## 框架结构
TeXEngine 框架提供了以下几个类和协议。
 |结构|类型|说明|
 |---|---|---|
 |`TeXEngine`|类|用于操作 TeX 引擎执行排版|
 |`EngineType`|结构体|用于指定 TeX 引擎的类型|
 |`TeXLogParser`|类|用于解析引擎编译后得到的日志文件|

 `TeXEngine` 框架是通过以下的想法把 XeTeX 和 pdfTeX 引擎带到 iOS 和 iPadOS 平台的。

 - 把 XeTeX 或者 pdfTeX 的源代码使用 WebAssembly 技术编译为 WASM 格式的文件以及辅助其在网页上运行的 JavaScript 脚本。
  > WASM 格式文件可以理解为 **可以在网页(HTML)上被执行的可执行文件**，而辅助 JavaScript 脚本是用于帮助浏览器运行 WASM 文件的脚本文件。
 - 使用 Apple 的 WebKit 框架，在 `WKWebView`（浏览器视图）中加载一个网页，这个网页中事先编写好了一些代码以加载上述的辅助 JavaScript 脚本。
  > 辅助 JavaScript脚本可以帮助我们加载其对应的 WASM 文件。

 - 通过调用 `WKWebView` 提供的相关方法，通过执行 JavaScript 命令的方式，控制 WASM 可执行文件中的 TeX 引擎执行实际的排版操作。
 - 剩余的问题是，**运行在 WASM 可执行文件中的 TeX 引擎是如何读取存储在用户磁盘中的 TeX Live 资源文件的**。答案是，TeXEngine 框架使用了大量 WebKit 技术以捕获所有的文件存取操作，例如实现了 `WKURLSchemeHandler` 协议等方法。

## API 说明

### 初始化引擎
初始化 `TeXEngine` 类的方法非常简单。
```swift
let engine = TeXEngine(engineType: .xetex) /* .pdftex */
```

### 文件查询服务
初始化此类后，还需要初始化 **TeX 资源文件查询服务**。


#### 准备 TeX Live 源文件
准备一个完全安装版本的 TeX Live 的 `TEXMF` 树的文件夹。在该文件夹下，需要包含 `texmf-dist`、`texmf-config` 和 `texmf-var` 这三个文件夹，在这三个文件夹中均需要包含 `ls-R` 文件。然后，把该文件夹拷贝至 `APP` 沙盒的某个文件夹中。接下来，我们始终假设该文件夹在设备上的 `URL` 为 `texliveURL`，这个 `texliveURL` 文件夹中包含了上述的三个子文件夹。

#### 加载引擎
加载引擎主要包括两个方面，一方面是加载 TeX 资源文件查询器，另一方面是加载运行引擎的网页。这些步骤是比较耗时的（大约需要 5s 至 12s 之间的时间）。以下给出了示例代码。
```swift
@MainActor
class TeXEngineController {
    let engine: TeXEngine = .init(engineType: .xetex)
    let texliveURL: URL

    init(texliveURL: URL) {
        self.texliveURL = texliveURL
    }

    /// completionHandler(true) 表示初始化成功
    func loadFileQuerier(completionHandler: @escaping (Bool) -> ()) {
        Task { @MainActor in
            completionHandler((try? await self.engine.loadEngine(texlive: texliveURL)) != nil)
        }
    }
}
```
如果以上初始化方法执行了闭包：`completionHandler(false)`，则说明没有设置好 `texliveURL` 中的文件结构，需要仔细调整文件结构再继续尝试。

#### TeX 文件查询器
为了加深对 TeX 资源文件查询器的理解，接下来简述文件查询器的基本行为。
- 文件查询器在初始化时将读取 `texmf-dist/ls-R`、`texmf-config/ls-R` 以及 `texmf-var/ls-R` 这三个文件（它们被称为 **ls-R 数据库**），并且把它们提供的所有信息放置在缓存中。
- 在执行文件查询（搜索文件名 `FILENAME` 对应的文件路径）时，文件查询器将先搜索被编译的 `tex` 文件所在的文件夹。
- 如果没有找到，文件查询器会深度（磁盘）搜索 `dynamicSearchResources` 中的所有文件夹 `URL` 的文件，并从中查找文件名对应的文件（从而查找到对应的路径）。  
- 如果仍然没有找到，将在第一步中提到的 ls-R 数据库缓存中查找 `FILENAME` 对应的文件路径。



### 编译类型

所谓的编译类型，其实指的是框架在执行排版时使用的编译方式。例如，当前框架支持使用 plain-TeX 编译方式、LaTeX 编译方式和 LaTeX 与 BibTeX 混合编译方式。

#### 当前框架支持的编译类型

目前支持 `CompileFormat.latex`、`CompileFormat.plain` 和 `CompileFormat.biblatex` 这三种编译类型。

#### 准备编译类型对应的格式文件

对于 `CompileFormat.latex` 或者 `CompileFormat.biblatex` 编译类型，它们实质上属于 LaTeX 格式，所以需要准备 LaTeX 格式文件。而 `CompileFormat.plain` 属于 `plain-TeX` 格式，所以需要准备 plain-TeX 格式文件。

格式文件其实和引擎、TeX Live 资源文件都有关联。也就是说，引擎不同，格式文件不同；TeX Live 资源文件的年份不同，格式文件不同。例如，框架已经自带了相应于 pdfTeX 引擎的 `pdflatex.fmt` 格式文件与相应于 XeTeX 引擎的 `xelatex.fmt` 格式文件，但是它们仅适用于 TeX Live 2022 的资源文件。

如果你准备好的 TeX Live 版本不是 2022，就需要自行编译新的格式文件；如果准备好的版本就是 2022，你可以跳过接下来和格式文件编译有关的部分。

#### 格式文件的编译

编译格式文件的具体过程如下。
- 确保 `pdflatex.ini` 和 `pdftex.ini` 等（与引擎相关）位于 `texliveURL` 文件夹中（可能很深）。
- 在之前的例子中的 `TeXEngineController` 中，添加以下实例方法（仅举 `xelatex.ini` 的例子）：
```swift
func compileFormatFile(outputDir: URL, completionHandler: @escaping (Bool) -> ()) {
    Task { @MainActor in
         completionHandler(try? await engine.compileFMT(for: .latex, target: outputDir) != nil)
    }
}
```
- 先初始化引擎的文件查询服务，然后再尝试编译格式文件。编译成功的话，可以去相应目录中获取对应的文件。

#### 自定义格式文件的路径
`TeXEngine` 类提供了两个属性：`plainFormatURL` 与 `latexFormatURL`。这两个属性分别指代了 LaTeX 格式和 plain-TeX 格式所对应的框架自带格式文件(TeX Live 2022)的 `URL`。在想要使用自定义格式文件时，可以对这两个属性进行赋值。

例如，假设新的 `xelatex.fmt` 的 `URL` 为 `newFMTURL`，在调用本类进行编译之前，只需：
```swift
engine.latexFormatURL = newFMTURL
```
即可指定新的 `xelatex.fmt` 的路径。

需要指出，传入给这两个静态属性的新的 `URL` 的文件名称必须符合以下规定，否则将导致编译失败。
|属性|文件名|
|---|---|
|`TeXEngine.plainFormatURL`|`xetex.fmt`, `pdftex.fmt`(相应于引擎类型)|
|`TeXEngine.latexFormatURL`|`xelatex.fmt`, `pdflatex.fmt`(相应于引擎类型)|

### `TeX` 文件的编译

#### 一个典型的例子
假设在 APP 沙盒的 `texProject` 文件夹中有以下三个文件: `main.tex`、`123.jpg` 和 `sub.tex`。其中，`main.tex` 文件的内容为：
```latex
\documentclass{ctexart}
\begin{document}
这是一个 \LaTeX 文件。

现在测试图片嵌入：
\includegraphics{123.jpg}

现在测试 `tex` 文件的导入：
\include{sub.tex}
\end{document}
```
而 `sub.tex` 文件的内容为：
```latex
这是 \texttt{sub.tex} 文件所包含的内容。
```
假设 `main.tex` 的 `URL` 为 `mainTeXFileURL`。仍接上例中的 `TeXEngineController`（由于使用了中文，这里必须使用 XeTeX 引擎），在其中添加以下方法：
```swift
func compile(completionHandler: @escaping (Bool) -> ()) {
    Task { @MainActor in
        completionHandler((try? await engine.compileTeX(by: .latex, tex: mainTeXFileURL, target: nil)) != nil)
    }
}
```
调用此方法后，在闭包 `completionHandler(_:)` 被呼叫后，我们可以去 `texProject` 文件夹中寻找输出的 `PDF` 文件与编译过程中引擎所生成的日志文件。

需要注意的是，`TeXEngine.compileTeX(by:tex:target)` 方法仅会在 **引擎崩溃** 时抛出错误。如果引擎崩溃，可以这样做：
```swift
func resetEngine() {
    try? await self.engine.cleanEngine()
}
```
但在调用此方法之前，需要确保已经加载了引擎（即调用了 `TeXEngine.loadEngine` 方法）。

#### 动态文件搜寻
有时会遇到用户想要安装 **文档类** 的需求。这时候可以访问 `TeXEngine` 实例的 `fileQuerier.dynamicSearchResources` 属性，并且把 **文档类所在的文件夹** 添加到该属性对应的列表中。

请注意，文件查询器将深度遍历 `fileQuerier.dynamicSearchResources` 属性里的所有文件夹内的所有内容，为了避免影响编译速度，最好不要在该属性中提供包含了较多文件的文件夹。

### XeTeX 的字体搜索

传统的（指之前 TeX Live 中自带的）XeTeX 引擎可以 **读取操作系统中安装的字体** 并把它们应用于排版过程。在 `Windows` 和 `Linux` 上，此功能依靠 `fontconfig` 框架实现；而在 `MacOS` 上，此功能依靠 `CoreText` 框架实现。

对于本框架，为了读取 `iOS` 与 `iPadOS` 上安装的本机字体，和 `MacOS` 的行为类似，框架也基于 `iOS` 上的 `CoreText` 框架，提供了一些字体相关的功能。

#### 字体数据库文件
字体数据库文件的路径为 `.../texmf-dist/font.json`（可能不存在）。
- 在初始化文件查询服务时，将会判断 `/texmf-dist` 中是否包含了 `font.json` 文件。
- `font.json` 其实是供 `TeXEngine` 的文件查询器使用的 **字体数据库**，用于（且仅用于）缓存 TeX Live 安装文件的中的所有 `opentype` 和 `truetype` 字体信息。
- 如果该文件存在，`TeXEngine` 的文件查询器将从这个文件中读取字体的数据（字体全名、字体族等）；如果不存在，框架将遍历 `/texmf-dist/font` 中安装的所有  `truetype` 和 `opentype` 字体，使用 `CoreText` 框架读取这些字体的信息，并且将这些信息写入到 `/texmf-dist/font.json` 文件中。

#### 字体搜索的行为
在框架内部的 XeTeX 引擎尝试搜索某个字体时，其会按照以下步骤依次进行搜索：（假设使用名称 `FONTNAME` 进行搜索）
- 先在 `font.json` 数据库中搜索，这时会依次把 `FONTNAME` 当做字体的 `PostScript` 名称和 `FullName` 名称进行搜索。
- 如果在上一步中没有搜索到任何结果，但是 `FONTNAME` 的格式类似于 `FONTNAME-FAMILY`（即：`FONTNAME` 的中间有一个 `-`，例如 `Semafor-常规体`），我们将把第一个出现的 `-` 的前半部分当做字体的 `FamilyName`（字体族），把后半部分当做字体的 `StyleName`（字体风格）。然后再在 `font.json` 中进行相应的搜索。
- 如果上一步中依旧没有搜索到任何结果，我们将使用 `CoreText` 框架，在 `iOS` 的系统字体数据库中查找字体。查找的方式和前边的两步完全相同。

#### `fontspec` 宏包的使用提示
根据以上字体搜索的步骤，如果想使用本框架去编译使用了 `fontspec` 宏包去自定义字体的 TeX 文件，在向 `fontspec` 宏包提供字体名称时，应尽可能地提供字体的 `PostScript` 名称。

另外，由于本框架提供的 XeTeX 引擎支持读取系统字体，用户可以使用 `iPadOS` 的系统字体安装功能去安装字体，安装好的字体可以被本框架提供的 XeTeX 引擎读取。

## 关于 `TeXLogParser` 的一些说明

这个类的使用非常简单。阅读以下例子即可自明。
```swift
class TeXLogParserController {
    let parser: TeXLogParser = .init()

    func parseLog(logURL: URL, completionHandler: ([TeXLogParseResultItem]?) -> ()) {
        guard let data = try? Data(contentsOf: logURL) else {
            completionHandler(nil)
            return
        }
        Task {
            let result = try? await self.parser.parse(data: data, encoding: .utf8)
            completionHandler(result)
        }
        //如果执行了 completionHandler(nil)，说明解析过程出现了错误
    }
}
```
其中，`parseLog` 的 `logURL` 参数应当传入 `TeX` 引擎输出的日志文件的 `URL`。
