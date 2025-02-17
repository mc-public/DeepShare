
//#region 辅助工具

/**
 * 更改某个文件(路径)对应的扩展名
 * @param {String} original 原本的文件路径，形如 `dir/123.tex` 等，允许以 `/` 结尾。
 * @param {String} extenionName 想要更改的扩展名，如 `pdf`。
 * @returns 返回被更改扩展名后的路径。如 `dir/123.tex/` 的输出值为 `dir/123.pdf`。返回值不以 `/` 结尾。
 */
function utility_path_change_extension(original, extenionName) {
    let file_name = utility_path_get_last_component(original);
    if (file_name.includes('.')) {
        let parts = original.split('.');
        parts.pop();
        parts.push(extenionName);
        return parts.join('.');
    } else {
        return original;
    }
    
}

/**
 * 移除某个路径的扩展名
 * @param {String} original 原本的文件路径，形如 `hello/123.tex` 等。
 * @returns 返回被更改扩展名后的文件路径，例如 `hello/123`。返回值不以 `/` 为结尾。
 */
function utility_path_remove_extension(original) {
    let file_name = utility_path_get_last_component(original);
    if (file_name.includes(original)) {
        let parts = original.split('.');
        parts.pop();
        return parts.join('.');
    } else {
        return original;
    }
}

/**
 * 移除某个路径的最后一个组成部分
 * @param {String} path 想要移除最后一个组成部分的路径
 * @returns {String} 返回被移除了最后一个组成部分的路径。例如，如果原值为 `123/123.tex`，则新值为 `123`。
 * 返回值不会以 `\` 作为结束符号。
 */
function utility_remove_path_last_component(path) {
    if (path.length == 0) {
        return "";
    } 
    let new_path = undefined;
    if (path.charAt(path.length - 1) === '/') {
        new_path = path.slice(0, -1);
    } else {
        new_path = path
    }
    let backslash_index = new_path.lastIndexOf('/');
    
    return new_path.substring(0, backslash_index);
}

/**
 * 获取路径的文件名称
 * @param {String} path 想要获取文件名称的路径。
 * @returns {String} 返回路径的文件名称。返回的文件名称不包含 `/` 斜杠。
 */
function utility_path_get_last_component(path) {
    if (path.length == 0) {
        return "";
    } 
    let new_path = undefined
    if (path.charAt(path.length - 1) === '/') {
        new_path = path.slice(0, -1);
    } else {
        new_path = path;
    }
    let components = new_path.split('/');
    return components[components.length - 1];
}




/**
 * 尝试删除某个路径对应的文件的符号链接。
 * @param {String} path 想要解除链接的文件路径。
 */
function utility_fs_unlink_file(path) {
    let fileState = undefined;
    try {
        fileState = FS.stat(path);
    } catch(err) {
        try {
            FS.unlink(path)
        } catch{}
        return
    }
    if (FS.isDir(fileState.mode)) {
        /// 在这里清理目录
        utility_fs_clean_directory(path);
    } else {
        FS.unlink(path)
    }
}

function utility_fs_clean_directory(dir) {
    let l = FS.readdir(dir);
    for (let i in l) {
        let item = l[i];
        if (item === "." || item === "..") {
            continue;
        }
        item = dir + "/" + item;
        let fsStat = undefined;
        try {
            fsStat = FS.stat(item);
        } catch (err) {
            console.log("[XeTeX Engine JS] Not able to fsstat " + item);
            continue;
        }
        if (FS.isDir(fsStat.mode)) {
            cleanDir(item);
        } else {
            try {
                FS.unlink(item);
            } catch (err) {
                console.log("[Engine.error] Not able to unlink " + item);
            }
        }
    }

    if (dir !== WORKROOT) {
        try {
            FS.rmdir(dir);
        } catch (err) {
            console.log("[Engine.error] Not able to top level " + dir);
        }
    }
}

/**
 * 把 `UInt8` 数组转换为 Base64 编码的字符串。
 * @param {Uint8Array} arrayBuffer 想要转换的缓冲区。
 * @returns {String} 返回转换后的字符串。
 */
function utility_arraybuffer_to_base64(arrayBuffer) {
    var base64    = '';
    var encodings = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  
    var bytes         = new Uint8Array(arrayBuffer);
    var byteLength    = bytes.byteLength;
    var byteRemainder = byteLength % 3;
    var mainLength    = byteLength - byteRemainder;
    var a, b, c, d;
    var chunk;
    for (var i = 0; i < mainLength; i = i + 3) {
      // Combine the three bytes into a single integer
      chunk = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
  
      // Use bitmasks to extract 6-bit segments from the triplet
      a = (chunk & 16515072) >> 18; // 16515072 = (2^6 - 1) << 18
      b = (chunk & 258048)   >> 12; // 258048   = (2^6 - 1) << 12
      c = (chunk & 4032)     >>  6; // 4032     = (2^6 - 1) << 6
      d = chunk & 63;               // 63       = 2^6 - 1
      base64 += encodings[a] + encodings[b] + encodings[c] + encodings[d];
    }
  
    // Deal with the remaining bytes and padding
    if (byteRemainder == 1) {
      chunk = bytes[mainLength];
  
      a = (chunk & 252) >> 2; // 252 = (2^6 - 1) << 2
  
      // Set the 4 least significant bits to zero
      b = (chunk & 3)   << 4; // 3   = 2^2 - 1
  
      base64 += encodings[a] + encodings[b] + '=='
    } else if (byteRemainder == 2) {
      chunk = (bytes[mainLength] << 8) | bytes[mainLength + 1];
      a = (chunk & 64512) >> 10; // 64512 = (2^6 - 1) << 10
      b = (chunk & 1008)  >>  4; // 1008  = (2^6 - 1) << 4
      // Set the 2 least significant bits to zero
      c = (chunk & 15)    <<  2; // 15    = 2^4 - 1
      base64 += encodings[a] + encodings[b] + encodings[c] + '=';
    }
    return base64;
}
//#endregion