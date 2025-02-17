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
#ifndef __XETEX_FONT_MGR_SP_H
#define __XETEX_FONT_MGR_SP_H

#include <xetexdir/XeTeXFontMgr.h>
#include "XeTeXFontMgr_js_font.h"


class XeTeXFontMgr_JS
    : public XeTeXFontMgr
{
public:
                                    XeTeXFontMgr_JS()
                                    { }
    virtual                         ~XeTeXFontMgr_JS()
                                    { }
protected:

    virtual void                    initialize();
    virtual void                    terminate();
    virtual void                    searchForHostPlatformFonts(const std::string& name);
    virtual NameCollection*         readNames(font_info_t* fontRef);
    virtual std::string             getPlatformFontDesc(PlatformFontRef font) const;
    virtual void                    addFontInfoArrayToCaches(const font_info_array_t* fonts);
    
};

#endif /* __XETEX_FONT_MGR_SP_H */
