//
//  XeTeXFontMgr_js_font.c
//
//
//  Created by 孟超 on 2023/7/26.
//

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <libparson/parson.h>
#include <malloc.h>
#include "./XeTeXFontMgr_js_font.h"

char **get_json_array_as_string_array(JSON_Array *json_array)
{
    if (json_array)
    {
        int count = json_array_get_count(json_array);
        char **result_array = malloc(count * sizeof(char *));
        for (int i = 0; i < count; i++)
        {
            result_array[i] = strdup(json_array_get_string(json_array, i));
        }
        return result_array;
    }
    #ifdef WEBASSEMBLY_DEBUG
    printf("失败: get_json_array_as_string_array\n");
    #endif
    return NULL;
}

font_info_t *get_font_info_from_js_object(JSON_Object *object)
{
    JSON_Object *root_object = object;
    const char *path = json_object_get_string(root_object, "path");
    const char *ps_name = json_object_get_string(root_object, "postScriptName");
    int index = (int)json_object_get_number(root_object, "index");
    JSON_Array *full_names = json_object_get_array(root_object, "fullNames");
    JSON_Array *family_names = json_object_get_array(root_object, "familyNames");
    JSON_Array *style_names = json_object_get_array(root_object, "styleNames");
    const char *extension_name = json_object_get_string(root_object, "extensionName");

    font_info_t *return_info = malloc(sizeof(font_info_t));
    return_info->path = strdup(path);
    return_info->extension = strdup(extension_name);
    return_info->post_script_name = strdup(ps_name);
    return_info->index = index;
    return_info->full_name_array = get_json_array_as_string_array(full_names);
    return_info->full_name_count = json_array_get_count(full_names);
    return_info->style_name_array = get_json_array_as_string_array(style_names);
    return_info->style_name_count = json_array_get_count(style_names);
    return_info->family_name_array = get_json_array_as_string_array(family_names);
    return_info->family_name_count = json_array_get_count(family_names);
    return return_info;
}

font_info_t *xetex_js_font_search_name(const string fontname)
{
    #ifdef WEBASSEMBLY_DEBUG
    printf("\n[字体 API]正在查找字体: fontname = %s\n", fontname);
    #endif
    char *result = find_font_js(fontname, false);
    JSON_Value *json_value = json_parse_string(result);
    if (json_value)
    { /* 解析成功 */
        JSON_Object *root_object = json_value_get_object(json_value);
        return get_font_info_from_js_object(root_object);
    }
    #ifdef WEBASSEMBLY_DEBUG
    printf("搜索失败: xetex_js_font_search_name\n");
    #endif
    return NULL;
}

/// @brief  搜索具有相同族名的字体
/// @param font_info_t 想要查找的字体
/// @return 返回一个数组
font_info_array_t *xetex_js_font_search_same_family(font_info_t *fontinfo)
{
    #ifdef WEBASSEMBLY_DEBUG
    printf("\n[字体 API]正在查找与 %s 同族的字体\n", fontinfo->post_script_name);
    printf("\n[字体 API]族: %s\n", *(fontinfo->family_name_array));
    #endif
    const char *json_string = find_font_js(fontinfo->post_script_name, true);
    JSON_Value *json_value = json_parse_string(json_string);
    if (json_value)
    {
        JSON_Object *root = json_value_get_object(json_value);
        JSON_Array *array = json_object_get_array(root, "infoArray");
        if (array) {
            int info_count = json_array_get_count(array);
            font_info_array_t* result_value = malloc(sizeof(font_info_array_t));
            font_info_t* info_array = malloc(sizeof(font_info_t) * info_count);
            for (int i = 0; i < info_count; i++)
            {
                JSON_Object* object = json_array_get_object(array, i);
                info_array[i] = *get_font_info_from_js_object(object);
            }
            result_value->font_array = info_array;
            result_value->font_count = info_count;
            return result_value;
        }
    }
    #ifdef WEBASSEMBLY_DEBUG
    printf("xetex_js_font_search_same_family: 未能成功查到同族字体!\n");
    #endif
    return NULL;
}