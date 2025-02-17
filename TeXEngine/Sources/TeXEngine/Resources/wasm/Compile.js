//
//  Compile.js
//  
//
//  Created by mengchao on 2024/2/19.
//  用于 JavaScript 与 pdfTeX 引擎模块的交互: 编译。
//TODO: (24.4.12 初步更改了一次编译状态值)
/**
 * 编译引擎的格式文件
 * 
 * @param {String} iniFileName 用于初始化的配置文件的名称。
 * 例如，对于 xetex，该值可以为 `xelatex.ini` 和 `xetex.ini`。
 * 
 * 只能在初始化以后进行调用操作。
 */
function engine_INITEX(ini_file_path) {
    resetStateToINIT();
    //FS.chdir(RESOURCES_PROJECT_ROOT);
    let ini_file_name = utility_path_get_last_component(ini_file_path);
    let ini_file_dir = utility_remove_path_last_component(ini_file_path);
    let fmt_file_path = utility_path_change_extension(ini_file_path, "fmt");
    try {
        FS.mkdirTree(ini_file_dir);
    } catch(err) {
        console.log(`[TeX Engine JS] 创建文件树失败: ${ini_file_dir}`);
    }
    const compile_FMT = cwrap(
        'engine_compile_tex_fmt',
        'number', /* 返回值:  */
        ['string', 'string']
    );
    let start_compile_time = performance.now();
    let returnValue = -1;
    try {
        returnValue = compile_FMT(ini_file_name, ini_file_dir);
    } catch(err) {
        console.log("运行错误." + err);
        return "[_EMPTY_]";
    }
    let end_compile_time = performance.now();
    console.log("[TeX Engine] INITEX: " + ini_file_path + "\n[TeX Engine]返回值为 " + returnValue);
    console.log("运行时间: " + ((end_compile_time - start_compile_time)/1000) + ' seconds.');
    console_dir_content(ini_file_dir);
    console.log(CONSOLE_OUTPUT);
    /// 获取数据
    if (returnValue != 0) { ///Format file failured!
        return "[_EMPTY_]";
    }
    console.log(fmt_file_path);
    try {
        let start_compile_time = performance.now();
        let fmt_buffer = FS.readFile(fmt_file_path, { encoding: 'binary' });
        let base64_string = utility_arraybuffer_to_base64(fmt_buffer);
        let end_compile_time = performance.now();
        console.log("转换时间: " + ((end_compile_time - start_compile_time)/1000) + ' seconds.');
        return base64_string;
    } catch(err) {
        console.error(err);
        console.error("[TeX Engine JS] fmt 格式文件已生成, 但是读取并解码时失败. 路径: " + fmt_file_path);
    }
    return "[_EMPTY_]";
}
window.engine_INITEX = engine_INITEX;

/**
 * 编译 TeX 文件
 * @param {String} tex_file_path tex文件的路径。
 * @param {*} fmt_file_name 格式文件的名称，例如 `xelatex.fmt`
 * @returns 返回被编码的 JSON 数据字符串。
 */
function engine_CompileTeX(tex_file_path, fmt_file_name, is_reset_to_init) {

    resetStateToINIT();
    
    let tex_file_directory = utility_remove_path_last_component(tex_file_path);
    let tex_file_name = utility_path_get_last_component(tex_file_path);
    let pdf_file_path = utility_path_change_extension(tex_file_path, "pdf");
    let synctex_file_path = utility_path_change_extension(tex_file_path, "synctex");
    let log_file_path = utility_path_change_extension(tex_file_path, "log");
    try { utility_fs_unlink_file(tex_file_directory) }  catch {};
    try { FS.unlink(tex_file_path)                   }  catch {};
    try { FS.unlink(pdf_file_path)                   }  catch {};
    try { FS.unlink(synctex_file_path)               }  catch {};
    try { FS.unlink(log_file_path)                   }  catch {};
    try { FS.mkdirTree(tex_file_directory)           }  catch(err) {
        console.log(`[TeX Engine JS] 创建文件树失败: ${ini_file_dir}`);
    }
    const compile_TeX = cwrap(
        'engine_compile_tex',
        'number', /* 返回值:  */
        ['string', 'string', 'string']
    );
    let compile_state = TEX_RETURN_CODE_TYPE.INTERNAL_EXIT.value; ///Default value is internal error.
    let start_compile_time = performance.now();
    try {
        compile_state = compile_TeX(tex_file_name, tex_file_directory, fmt_file_name);
    } catch(err) {
        console.error("[TeX Engine JS] 引擎内部错误: " + err);
        c_print("ERROR:" + err + "STATE:" + compile_state);
        //此时引擎崩溃.
    }
    /// 判断当前引擎是否发生了内存不足错误
    /// c_print("Engine State: "+ compile_state);
    console.log("[TeX Engine JS] 编译日志: \n" + CONSOLE_OUTPUT);
    /// 打包的文件: synctex, pdf, log
    let pdf_send_string = null;
    let synctex_send_string = null;
    let log_send_string = null;
    try {
        let pdf_buffer = FS.readFile(pdf_file_path, { encoding: 'binary' });
        pdf_send_string = utility_arraybuffer_to_base64(pdf_buffer);
    } catch(err) {
        console.error("未解析成功 PDF 文件: " + err);
    }
    try {
        synctex_send_string = FS.readFile(synctex_file_path, { encoding: 'utf8'});
    } catch(err) {
        console.error("未解析成功 SyncTeX 文件: " + err);
    }
    try {
        log_send_string = FS.readFile(log_file_path, { encoding: 'utf8' });
    } catch(err) {
        console.error("未解析成功 Log 文件: " + err);
    }
    let end_compile_time = performance.now();
    let send_object = {};
    send_object["tex_state"] = compile_state;
    if (pdf_send_string !== null) {
        send_object["pdf_base64_string"] = pdf_send_string;
        send_object["no_pdf_output"] = false
    } else {
        send_object["no_pdf_output"] = true
    }
    if (log_send_string !== null) {
        send_object["log_string"] = log_send_string;
    }
    if (synctex_send_string !== null) {
        send_object["synctex_string"] = synctex_send_string;
    }
    console.error("[TeX Engine JS] Compile Completion. Time:" + ((end_compile_time - start_compile_time)/1000) + ' seconds.');
    return send_object;
}
window.engine_CompileTeX = engine_CompileTeX;

/**
 * 使用 BibTeX 编译 TeX 文件
 * @param {String} tex_file_path tex文件的路径。
 * @param {*} fmt_file_name 格式文件的名称，例如 `xelatex.fmt`
 * @returns 返回被编码的 JSON 数据字符串。
 */
function engine_CompileTeX_WithBibTeX(tex_file_path, fmt_file_name) {
    resetStateToINIT();
    let tex_file_directory = utility_remove_path_last_component(tex_file_path);
    let tex_file_name = utility_path_get_last_component(tex_file_path);
    let pdf_file_path = utility_path_change_extension(tex_file_path, "pdf");
    let synctex_file_path = utility_path_change_extension(tex_file_path, "synctex");
    let log_file_path = utility_path_change_extension(tex_file_path, "log");
    let aux_file_path = utility_path_change_extension(tex_file_path, "aux");
    let blg_file_path = utility_path_change_extension(tex_file_path, "blg");
    let bbl_file_path = utility_path_change_extension(tex_file_path, "bbl");
    ///读取 bbl 文件内容

    let bbl_string_old = null;
    try { bbl_string_old = FS.readFile(bbl_file_path, { encoding: 'utf8' }) } catch {};
    try { utility_fs_unlink_file(tex_file_directory) }  catch {};
    try { FS.unlink(aux_file_path)                   }  catch {};
    try { FS.unlink(tex_file_path)                   }  catch {};
    try { FS.unlink(pdf_file_path)                   }  catch {};
    try { FS.unlink(synctex_file_path)               }  catch {};
    try { FS.unlink(log_file_path)                   }  catch {};
    try { FS.mkdirTree(tex_file_directory)           }  catch(err) {
        console.log(`[TeX Engine JS] 创建文件树失败: ${ini_file_dir}`);
    }
    const bibtex_compile = cwrap(
        'engine_compile_bibtex',
        'number', 
        ['string', 'string']
    );
    /* 第一次 tex 编译 */
    let firstCompileResult = null
    try {
        firstCompileResult = engine_CompileTeX(tex_file_path, fmt_file_name, true);
    } catch {}
    let state1 = firstCompileResult["tex_state"]
    if (firstCompileResult === null || (new TEX_RETURN_CODE_TYPE(state1)).isFatalError()) { /* 崩溃级别错误 */
        let send_object = {};
        send_object["tex_state"] = state1;
        send_object["no_pdf_output"] = true;
        send_object["error_description"] = "First TeX Compile Failure";
        return send_object;
    } else if (firstCompileResult["tex_state"] != 0) {
        return firstCompileResult;
    } 
    /* bibtex 编译 */
    resetStateWithoutUnlinkFileCache();
    let bibtex_state = -1;
    try {
        bibtex_state =  bibtex_compile(tex_file_name, tex_file_directory);
    } catch {}
    let bbl_string_new = null
    try { bbl_string_new = FS.readFile(bbl_file_path, { encoding: 'utf8' }) } catch {  };
    let blg_string = null
        try { blg_string = FS.readFile(blg_file_path, { encoding: 'utf8' }) } catch {  };
    if (bibtex_state == -1) { /* 严重内部错误 */
        firstCompileResult["bibtex_state"] = bibtex_state;
        firstCompileResult["error_description"] = "BibTeX Compile Failure";
        return  firstCompileResult;
    } else if (bibtex_state <= -2) { /* 没有产生 aux 文件 */
        firstCompileResult["bibtex_state"] = bibtex_state;
        return firstCompileResult;
    } else if (bibtex_state >= 2) { /* BibTeX 编译时出现错误 */
        /* 此时一定有 bbl 与 blg 文件数据 */
        firstCompileResult["bibtex_state"] = bibtex_state;
        if (bbl_string_new !== null && blg_string !== null) {
            firstCompileResult["bbl_string"] = bbl_string_new;
            firstCompileResult["blg_string"] = blg_string;
        } else {
            firstCompileResult["bibtex_state"] = -1;
        }
        return firstCompileResult;
    }
    
    if (bbl_string_old !== null && bbl_string_new !== null && bbl_string_new == bbl_string_old) {
        /// 此时旧串等于新串, 我们直接返回即可, 这是因为 bbl 文件的内容没变
        
        firstCompileResult["bibtex_state"] = bibtex_state;
        firstCompileResult["directly_return"] = true;
        firstCompileResult["bbl_string"] = bbl_string_new
        if (blg_string !== null) {
            firstCompileResult["blg_string"] = blg_string;
        }
        return firstCompileResult;
    } else if (bbl_string_new !== null && bbl_string_new.trim() === '') {
        /// 此时 bbl 文件内容为空. 我们直接返回
        let blg_string = null
        try { blg_string = FS.readFile(blg_file_path, { encoding: 'utf8' }) } catch {};
        firstCompileResult["bibtex_state"] = bibtex_state;
        firstCompileResult["bbl_string"] = bbl_string_new
        if (blg_string !== null) {
            firstCompileResult["blg_string"] = blg_string;
        }
        return firstCompileResult;
    }
    /// 再执行两次编译
    let thirdCompileResult = null;
    resetStateWithoutUnlinkFileCache();
    try {
        engine_CompileTeX(tex_file_path, fmt_file_name, false);
    } catch {
        console.error("Second TeX Compile Crashed")
    }
    resetStateWithoutUnlinkFileCache();
    try {
        thirdCompileResult = engine_CompileTeX(tex_file_path, fmt_file_name, false);
    } catch {
        console.error("Third TeX Compile Crashed");
        console.error(err);
    }
    let tex_state3 = thirdCompileResult["tex_state"]
    if (thirdCompileResult === null || (new TEX_RETURN_CODE_TYPE(tex_state3)).isFatalError()) {
        let send_object = {};
        send_object["tex_state"] = tex_state3;
        send_object["bibtex_state"] = bibtex_state;
        send_object["no_pdf_output"] = true;
        send_object["error_description"] = "Third TeX Compile Crashed";
        return send_object;
    }
    /// 读取信息
    let current_bbl_string = null;
    let current_blg_string = null;
    try {
        current_bbl_string = FS.readFile(bbl_file_path, { encoding: 'utf8' });
    } catch {}
    try {
        current_blg_string = FS.readFile(blg_file_path, { encoding: 'utf8' });
    } catch {}
    thirdCompileResult["bibtex_state"] = bibtex_state;
    if (current_bbl_string) {
        thirdCompileResult["bbl_string"] = current_bbl_string;
    }
    if (current_blg_string) {
        thirdCompileResult["blg_string"] = current_blg_string;
    }
    return thirdCompileResult;
}
window.engine_CompileTeX_WithBibTeX = engine_CompileTeX_WithBibTeX;