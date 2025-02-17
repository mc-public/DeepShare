/*
 Copyright (c) 2022 Clerk Ma

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/
#include <w2c/config.h>

#include "XeTeXFontMgr_js.h"

/*
TODO: 在 XeTeXFontMgr.h 里添加相应的定义 
typedef FcPattern* PlatformFontRef;
*/

XeTeXFontMgr::NameCollection*
XeTeXFontMgr_JS::readNames(font_info_t* spec_font)
{
    NameCollection* names = new NameCollection;
    int full_name_count = spec_font->full_name_count;
    int family_name_count = spec_font->family_name_count;
    int style_name_count = spec_font->style_name_count;
    int index = 0;
    /* 添加全名 字体族名 风格名*/
    for (index = 0; index < full_name_count; index++) {
        appendToList(&names->m_fullNames, (spec_font->full_name_array)[index]);
    }
    index = 0;
    for (index = 0; index < family_name_count; index++) {
        appendToList(&names->m_familyNames, (spec_font->family_name_array)[index]);
    }
    index = 0;
    for (index = 0; index < style_name_count; index++) {
        appendToList(&names->m_styleNames, (spec_font->style_name_array)[index]);
    }

    names->m_psName = spec_font->post_script_name;
    names->m_subFamily = *(spec_font->style_name_array);
    
    return names;
}

void
XeTeXFontMgr_JS::addFontInfoArrayToCaches(const font_info_array_t* fonts)
{
    if ((!fonts) || ((fonts->font_count) <= 0))  {
        return;
    }
    int i = 0;
    for (i = 0; i < (fonts->font_count); i++)
    {
        font_info_t* font = (fonts->font_array) + i;
        addToMaps(font, readNames(font));
    }
}

void
XeTeXFontMgr_JS::searchForHostPlatformFonts(const std::string& name)
{
    /// 先直接搜
    const char* font_name = name.c_str();
    font_info_t* font = xetex_js_font_search_name((const string)font_name);
    if (font != NULL) {
        font_info_array_t* same_family_fonts = xetex_js_font_search_same_family(font);
        addFontInfoArrayToCaches(same_family_fonts);
    }

}

void
XeTeXFontMgr_JS::initialize()
{
    //spec = specimen_init();
}

void
XeTeXFontMgr_JS::terminate()
{
    //specimen_tini(spec);
}

std::string
XeTeXFontMgr_JS::getPlatformFontDesc(PlatformFontRef font) const
{
    return "[unknown]";
    /*
    if (font == NULL)
        return "[unknown]";
    else
    {
        return font->path;
    }
    */
}
