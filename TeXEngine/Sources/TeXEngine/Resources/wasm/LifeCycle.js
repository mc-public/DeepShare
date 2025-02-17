//
//  LifeCycle.js
//  
//
//  Created by mengchao on 2023/7/21.
//  用于 JavaScript 与 TeX 引擎模块的交互。


//#region 模块配置与内存管理

function _allocate(content) {
    let res = _malloc(content.length);
    HEAPU8.set(new Uint8Array(content), res);
    return res; 
}

let ModuleSet = {
    'print': c_print,
    'printErr': c_printerr,
    'preRun': c_preRun,
    'postRun': c_postRun,
    'onAbort': c_onAbort 
}

for (let key in ModuleSet) {
    Module[key] = ModuleSet[key];
}

function c_print_memory() {
    let mb = (wasmMemory.buffer.byteLength / 1024) / 1024
    let str =  "内存用量: " + mb + "MB"
    console.error(str);
    send_console_output_to_webview(str)
}

function send_console_output_to_webview(content) {
    window.webkit.messageHandlers.TeXLogHandler.postMessage(content);
}
/**
 * 引擎尝试调用 `printf` 往 `stdout` 中输出内容时挂钩的方法
 * @param {String} output - 输出的值
 */
function c_print(output) {
    //c_print_memory();
    CONSOLE_OUTPUT += (output + "\n");
    send_console_output_to_webview(output);
}



/**
 * 引擎尝试调用 `printf` 往 `stderr` 中输出内容时挂钩的方法
 * @param {String} output 
 */
function c_printerr (output) {
    c_print_memory();
    console.error(output);
    CONSOLE_OUTPUT += (output + "\n");
    send_console_output_to_webview(output);
}

/**
 * 引擎初始化完毕但运行 `main` 函数之前挂钩的方法
 * 在此方法中进行 `FileSystem` 的准备工作
 */
function c_preRun () {
    console.log("[XeTeX Engine]: preRun...")
}

/**
 * 引擎结束运行 `main` 函数后挂钩的方法
 */
function c_postRun () {
    console.log("[XeTeX Engine]: postRun...");
    backupINITMemory(); /* 在这里备份内存 */
}

/**
 * 当任何 `C`函数被 `abort` 终止时挂钩的方法
 */
function c_onAbort() {
    c_print_memory();
    console.error("[XeTeX Engine]: ERROR(ABORT).");
}

/**
 * 初始化以后备份的内存区域
 * 
 * 在 Model 的 postRun 过程后进行备份。
 */
let MEMORY_INIT = undefined;

/**
 * 把当前的内存备份至全局 `MEMORY_INIT` 中
 * 
 * 主要用于在初始化以后进行立即备份，以后编译时再行恢复，以避免内存泄漏。此函数应当在 `Model` 的 `postRun` 时只被调用一次。
 */
function backupINITMemory() {
    let backup = wasmMemory.buffer;
    let copiedArray = new Uint8Array(backup)
    let copied = new Uint8Array(copiedArray.byteLength);
    console.log("[Backup Memory] size: " + copied.length);
    copied.set(copiedArray);
    MEMORY_INIT = copied;
}



/**
 * 把当前的内存重设为初始化状态，重置工程文件等的缓存
 * 
 * 在每次编译之前进行调用，这样可以把内存完全重置为之前的状态, 并且会解除所有动态文件资源的链接。
 */
function resetStateToINIT() {
    closeFSStreams();
    if (MEMORY_INIT) {
        let newCopied = new Uint8Array(wasmMemory.buffer);
        newCopied.set(MEMORY_INIT);
    }
    CONSOLE_OUTPUT = "";
    for (let key in RESOURCES_DYNAMIC_CACHE) {
        utility_fs_unlink_file(RESOURCES_DYNAMIC_CACHE[key]);
    }
    RESOURCES_DYNAMIC_CACHE = {};
    for (let key in RESOURCES_PROJECT_CACHE) {
        utility_fs_unlink_file(RESOURCES_PROJECT_CACHE[key]);
    }
    RESOURCES_PROJECT_CACHE = {};
}

function resetStateWithoutUnlinkFileCache() {
    //closeFSStreams();
    // if (MEMORY_INIT) {
    //     let newCopied = new Uint8Array(wasmMemory.buffer);
    //     newCopied.set(MEMORY_INIT);
    // }
    resetStateToINIT()
}

/**
 * 关闭 FileSystem 的文件读写
 */
function closeFSStreams() {
    for (let i = 0; i < FS.streams.length; i++) {
        let stream = FS.streams[i];
        if (!stream || stream.fd <= 2) {
            continue;
        }
        FS.close(stream);
    }
}

/** 在控制台中输出目录中的文件名
 * - 输出形式类似于 [".","..","123.tex"]
 */
function console_dir_content(dir) {
    let l = FS.readdir(dir);
    console.log("[XeTeX Engine] Directory Path: " + dir + "所含内容: " + l);
}

/**
 * 设置引擎类型为 pdfTeX
 */
function set_engine_type_pdftex() {
    CURRENT_ENGINE_TYPE = pdfTeX_TYPE;
    CURRENT_ENGINE_NAME = "pdfTeX"
    console.log("[Engine] Type: pdfTeX")
}

/**
 * 设置引擎类型为 XeTeX
 */
function set_engine_type_xetex() {
    CURRENT_ENGINE_TYPE = XeTeX_TYPE;
    CURRENT_ENGINE_NAME = "XeTeX"
    console.log("[Engine] Type: XeTeX")
}

/**
 * 
 * @returns 当前引擎的
 */
function kpse_get_invocation_name() {
    return _allocate(intArrayFromString(CURRENT_ENGINE_NAME));
}

//#endregion

