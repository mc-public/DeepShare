//
//  GlyphQuery.js
//  
//
//  Created by mengchao on 2024/2/19.
//  用于 JavaScript 与 pdfTeX 引擎模块的交互: 字体查找。

/// 当前文件中使用的字形查询缓存
const GLYPH_CACHE = { name: null, dpi: null };

function pdftex_will_search_glyph(passed_fontname, dpi) { /* pk file format */
    GLYPH_CACHE.name = null;
    GLYPH_CACHE.dpi = null; /*先清空*/
    font_name = UTF8ToString(passed_fontname);
    let result = kpse_find_glyph_impl(font_name, dpi);
    GLYPH_CACHE.name = _allocate(intArrayFromString(result.font_path))
    GLYPH_CACHE.dpi = result.dpi
}


function kpse_find_glyph_impl(font_name, dpi) {
    let format = 1; /* pk file */
    console.log("[TeX Engine JS] 查找字形文件: " + font_name + "格式: " + format);
    const kpse_cache_key = format + "/" + font_name
    /* 通过 cacheKey 访问到的文件的结果是唯一的, 要么是 texlive源文件, 要么是
    编译依赖文件, texlive 源文件时会加进源列表, 非texlive源文件则不加入源列表, 从
    而这里使用键的方式是合理的!
    */
    let file_path = null;
    let path_is_in_cache = true
    if (kpse_cache_key in RESOURCES_GLYPH_CACHE) { /* 工作区文件路径缓存 */
        file_path = RESOURCES_GLYPH_CACHE[kpse_cache_key];
    } else {
        path_is_in_cache = false;
    }
    if (path_is_in_cache) {
        console.log("[TeX Engine JS] 在缓存中找到了字形文件路径: " + file_path);
        return _allocate(intArrayFromString(file_path));
    }
    /// 把字符串和格式转换为 json 字符串, 然后打包传送
    let request_objet = {
        font_name: font_name,
        dpi: dpi
    }
    let json_string = JSON.stringify(request_objet);
    let base64_string = btoa(json_string);
    const remote_url = FILE_SERVICE_HTTP_POINT + encodeURIComponent(base64_string);
    console.log("[TeX Engine JS] 请求字形文件查询: " + remote_url);
    let xhr = new XMLHttpRequest();
    xhr.responseType = "arraybuffer";
    xhr.open("GET", remote_url, false);
    xhr.setRequestHeader("pdfTeX-Font-Glyph-Query-Info", json_string);
    console.log("发送文件请求: " + remote_url);
    try {
        xhr.send();
    } catch (err) {
        console.error("[TeX Engine JS] FIXME: 原生端发送了失败请求.");
        return 0;
    }
    let file_buffer = xhr.response;
    file_path = xhr.getResponseHeader('PK-Glyph-Path'); /* pk 文件生成后的路径, 或者原来的路径 */
    let file_dpi = xhr.getResponseHeader('PK-Glyph-DPI'); 
    let need_return = false;
    if (file_path === null || file_dpi === null) {
        need_return = true;
    }
    if (need_return) {
        console.log("[TeX Engine JS] 没有查到文件" + font_name);
        return 0;
    }
    console.log("[TeX Engine JS] 创建文件: " + file_path + "类型: " + file_resource_type);
    let file_dir = utility_remove_path_last_component(file_path);
    try {
        FS.mkdirTree(file_dir);
    } catch (err) {
        console.log("[TeX Engine JS] 创建文件夹" + file_dir + "失败. 原因: " + err);
    }
    try {
        FS.writeFile(file_path, new Uint8Array(file_buffer));
    } catch (err) {
        console.log("[TeX Engine JS] 写文件失败: " + file_path);
    }
    return { font_path: file_path, dpi: file_dpi };

}

function pdftex_get_glyph_name() {
    return _allocate(intArrayFromString(GLYPH_CACHE.name));
}

function pdftex_get_glyph_dpi() {
    return GLYPH_CACHE.dpi;
}

function pdftex_did_search_glyph() {
    GLYPH_CACHE.name = null;
    GLYPH_CACHE.dpi = null;
}

