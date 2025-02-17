mergeInto(LibraryManager.library, {
    /* TeXEngine Search File */
    kpse_find_file_js: function (nameptr, format, mustexist) {
        return kpse_find_file_impl(nameptr, format, mustexist);
    },
    /* TeXEngine search invocation name */
    kpse_get_invocation_name_js: function () {
        return kpse_get_invocation_name();
    },
    /* libdpx Search File */
    kpse_find_file_js: function (nameptr, format) {
        return kpse_find_file_impl(nameptr, format);
    },
    /* xetex Search font */
    find_font_js: function (nameptr, isCheckSameFamily) {
        return find_font(nameptr, isCheckSameFamily);
    },
    /* pdftex Search pk delegate */
    kpse_find_glyph_js_begin: function (passed_fontname, dpi, kpse_file_format_type) {
        return pdftex_will_search_glyph(passed_fontname, dpi);
    },
    kpse_get_glyph_name_js: function () {
        return pdftex_get_glyph_name();
    },
    kpse_get_glyph_dpi_js: function () {
        return pdftex_get_glyph_dpi();
    },
    kpse_find_glyph_js_end: function () {
        pdftex_did_search_glyph();
    },
    kpse_set_pdftex_engine_js: function() {
        set_engine_type_pdftex();
    },
    kpse_set_xetex_engine_js: function() {
        set_engine_type_xetex();
    },
    /// Memory Debug
    kpse_show_memory_usage: function() {
        // c_print_memory();
    }
});

