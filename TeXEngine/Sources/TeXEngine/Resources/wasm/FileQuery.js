//
//  FileQuery.js
//  
//
//  Created by mengchao on 2024/2/19.
//  用于 JavaScript 与 TeX 引擎模块的交互: 文件查找。


function kpse_find_file_impl(nameptr, format, _mustexist) {
    let file_name = UTF8ToString(nameptr);
    console.log("[TeX Engine JS] 查找文件: " + file_name + "格式: " + format);
    const kpse_cache_key = format + "/" + file_name
    /* 通过 cacheKey 访问到的文件的结果是唯一的, 要么是 texlive源文件, 要么是
    编译依赖文件, texlive 源文件时会加进源列表, 非texlive源文件则不加入源列表, 从
    而这里使用键的方式是合理的!
    */
    let file_path = undefined;
    let path_is_in_cache = true
    if (kpse_cache_key in RESOURCES_PROJECT_CACHE) { /* 工作区文件路径缓存 */
        file_path = RESOURCES_PROJECT_CACHE[kpse_cache_key];
    } else if (kpse_cache_key in RESOURCES_DYNAMIC_CACHE) { /* 动态文件路径缓存 */
        file_path = RESOURCES_DYNAMIC_CACHE[kpse_cache_key];
    } else if (kpse_cache_key in RESOURCES_TEXLIVE_CACHE) {
        file_path = RESOURCES_TEXLIVE_CACHE[kpse_cache_key];
    } else {
        path_is_in_cache = false;
    }
    if (path_is_in_cache) {
        //console.log("[TeX Engine JS] 在缓存中找到了路径: " + file_path);
        return _allocate(intArrayFromString(file_path));
    }
    /// 把字符串和格式转换为 json 字符串, 然后打包传送
    let request_objet = {
        name: file_name,
        format: format
    }
    let json_string = JSON.stringify(request_objet);
    let base64_string = btoa(json_string);
    const remote_url = FILE_SERVICE_HTTP_POINT + encodeURIComponent(base64_string);
    //console.log("[TeX Engine JS] 请求文件查询: " + remote_url);
    let xhr = new XMLHttpRequest();
    xhr.responseType = "arraybuffer";
    xhr.open("GET", remote_url, false);
    xhr.setRequestHeader("File-Info-JSON", json_string);
    xhr.setRequestHeader("Kpathsea-Regular-File-Query", CURRENT_ENGINE_NAME);
    console.log("发送文件请求: " + remote_url);
    try {
        xhr.send();
    } catch (err) {
        console.error("[TeX Engine JS] FIXME: 原生端发送了失败请求.");
        return 0;
    }
    let file_buffer = xhr.response;
    file_path = xhr.getResponseHeader('File-Absolute-Path');
    file_resource_type = xhr.getResponseHeader('File-Resource-Type');
    let need_return = false
    switch (file_resource_type) {
        case "200": /* PROJECT 文件 */
            RESOURCES_PROJECT_CACHE[kpse_cache_key] = file_path;
            break;
        case "300": /* 动态文件 */
            RESOURCES_DYNAMIC_CACHE[kpse_cache_key] = file_path;
            break;
        case "400": /* texlive 源文件 */
            RESOURCES_TEXLIVE_CACHE[kpse_cache_key] = file_path;
            break;
        default: /* 这种情况不可能发生 */
            need_return = true
            break;
    }
    if (need_return) {
        console.log("[TeX Engine JS] 没有查到文件" + file_name);
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
    return _allocate(intArrayFromString(file_path));

}


/**
 * XeTeX 的查找字体的具体实现。
 * @param {String} nameptr 用于查找的字体名称。
 * @param {boolean} isCheckSameFamily 是否查找同族字体。
 */
function find_font(nameptr, isCheckSameFamily) {
    let font_name = UTF8ToString(nameptr);
    console.log("[TeX Engine JS] 查找字体: " + font_name + "类型: " + (isCheckSameFamily ? "Family" : "Font"));
    /* 查找到的字体无需直接进入缓存. 
     */
    let request_string = btoa(font_name);
    const remote_url = FILE_SERVICE_HTTP_POINT + encodeURIComponent(request_string);
    console.log("[TeX Engine JS] 请求字体查询: " + remote_url + "name" +  font_name);
    let xhr = new XMLHttpRequest();
    xhr.responseType = "text";
    xhr.open("GET", remote_url, false); /* sync */
    xhr.setRequestHeader("XeTeX-Font-Query-Info", font_name);
    xhr.setRequestHeader("XeTeX-Font-Query-Type", isCheckSameFamily ? "Family" : "Font")
    console.log("发送字体查找请求: " + remote_url);
    try {
        xhr.send();
    } catch (err) {
        console.log("[XeTeX Engine JS] FIXME: 原生端发送了失败请求. ")
        return 0;
    }
    let result_info_json = xhr.getResponseHeader('Font-Info-Query-Result');
    if (result_info_json.length <= 0) {
        console.log("[XeTeX Engine JS] 没有找到字体: " + font_name);
        return 0;
    }
    console.error(JSON.parse(result_info_json));
    return _allocate(intArrayFromString(result_info_json));

}