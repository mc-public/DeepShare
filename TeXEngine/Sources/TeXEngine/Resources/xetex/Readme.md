# WebXeTeX

## 简介
`WebXeTeX` 是 `iOS/iPadOS` 平台的全功能 `TeX` 发行版—— `Butter` 的 `swift package` 组件——`TeXEngine` 的依赖库。其基于 `texlive 2023` 构建，但是又对引擎的字体查找和文件查找等部分进行了重大修改，用于在 `iOS` 平台的 `WKWebView` 视图中运行 `XeTeX` 引擎。

## 与 `XeTeX` 的区别
目前，`texlive 2023` 提供的 `XeTeX` 引擎仅支持 `Windows/Linux/MacOS` 平台，想要把该引擎移植到 `web` 视图中是比较困难的。本框架深受 `SwiftLaTeX` 遗产项目的启发，在该项目的基础上进行构建，最终重写了该项目近 90% 的源代码，形成了一个可以在 `iOS` 平台的 `WKWebView` 中稳定运行的私有项目。

该引擎的 `TeX` 部分和 `XeTeX` 完全相同。值得强调的不同点体现在 **文件查找** 和 **字体查找** 上。`XeTeX` 在原有平台上的文件查找功能依赖于 `kpathsea` 路径搜索库，在原有平台上的字体查找功能则依赖于 `Fontconfig` 或者 `CoreText` 库。但是，在 `Web` 框架中，这些库均不可用。因此，我们使用 `emsdk` 的 `Library` 功能，为引擎实现了全新的文件与字体查找功能。由于 `emsdk` 使用虚拟文件系统，所以这些实现与原先的库的实现完全不同，还借助了 `iOS` 平台的很多原生功能。

## 构建方法

1. 安装 `emsdk`。执行以下命令:
  
```
 cd ~ && git clone https://github.com/emscripten-core/emsdk.git
  
 cd emsdk

 git pull

 ./emsdk install latest

 ./emsdk activate latest
```
2. 克隆本工程到 `xetex` 文件夹中，在 `VSCode` 中打开该文件夹。然后，键盘快捷键 `cmd+shift+b` 以进行编译。编译不应当报错（但是可能出现一些和 `Harfbuzz` 库有关的警告，这些不用关心）。
3. 如果不想使用 `VSCode` 作为 IDE，也可以在终端中直接构建。`cd` 到文件夹中，执行 `. ./openemsdk.sh && make` 即可构建。执行 `make clean` 即可进行清理。


## 使用方法

在 `iOS` 工程中拖入 `./xetex.js`，`./xetex.wasm`，`./wasm/XeTeXEngine.html`，然后在 `WKWebView` 中加载网页。需要注意的是，配置 `WKWebView` 时必须开启全局文件访问功能。

详细的示例可以参考 `TeXEngine` 框架中的有关实现。我在 `TeXEngine` 框架中使用了本框架提供的所有功能。