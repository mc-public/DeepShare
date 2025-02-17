//
//  XeTeXFontMgr_js_font.h
//  
//
//  Created by 孟超 on 2023/7/26.
//


#include <stdio.h>


#ifndef XeTeXFontMgr_js_font
#define XeTeXFontMgr_js_font

#ifdef __cplusplus
extern "C"
{
#endif

#define XETEX_JS_FONT_VERSION "20230726"

typedef char* string;

struct font_info
{
    /* 字体存放的虚拟路径 */
    string path;
    /* 字体的扩展名(例如otf, 小写且不以`.` 开始)*/
    string extension;
    /* 字体 PostScript 名称 (Nullable)*/
    string post_script_name;
    /* 字体全名数组 */
    string *full_name_array;
    /* 字体全名个数 */
    int full_name_count;
    /* 字体族名列表 */
    string *family_name_array;
    /* 字体族名个数 */
    int family_name_count;
    /* 字体风格名(subfamily)列表 */
    string *style_name_array;
    /* 字体风格名个数 */
    int style_name_count;
    /* 字体索引值(仅在该字体对应某字集时才可能不为 0) */
    int index;
};

/// @brief  字体信息实例 使用时必须在堆区分配内存!
typedef struct font_info font_info_t;

typedef font_info_t* PlatformFontRef;
typedef font_info_t PlatformFont; 

struct font_info_array
{
    /* 具有相同字体族的字体 */
    font_info_t* font_array;
    /* 以上序列中所含字体的数量 */
    int font_count;
};

/// @brief  同族字体信息索引 使用时必须在堆区分配内存!
typedef struct font_info_array font_info_array_t;


// NOTE: 字体 API 

/// @brief 搜索字体族
//font_info_t* xetex_js_font_search_family(string name);

/// @brief 按字体名称搜索字体
font_info_t* xetex_js_font_search_name(const string fontname);

/// @brief 搜索同族字体
font_info_array_t* xetex_js_font_search_same_family(font_info_t* fontinfo);
/// @brief 由 Javascript 提供的字体查找函数
extern char* find_font_js(const char* name, bool type);

#ifdef __cplusplus
}
#endif

#endif /* XeTeXFontMgr_js_font */