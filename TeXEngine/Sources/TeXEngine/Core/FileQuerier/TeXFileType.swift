//
//  TeXFileType.swift
//  
//
//  Created by mengchao on 2023/7/20.
//

import Foundation

/// 表示 `TeX` 引擎进行文件搜索时的所有可能类型的枚举。
///
/// 在进行路径搜索时会用到此枚举。
public enum TeXFileType: Int, Hashable, Sendable {
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.gf` 文件
    case kpse_gf_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.pk` 文件
    case kpse_pk_format
    /// kpythsea 可搜寻的两种文件类型
    ///
    /// 表示 `*.gf` 以及 `*.pk` 文件
    case kpse_any_glyph_format /* ``any'' meaning gf or pk */
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.tfm` 文件
    case kpse_tfm_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.afm` 文件
    case kpse_afm_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.base` 文件
    case kpse_base_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.bib` 文件
    case kpse_bib_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.bst` 文件
    case kpse_bst_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.cnf` 文件
    case kpse_cnf_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.db` 文件
    case kpse_db_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.fmt` 文件
    case kpse_fmt_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.fontmap` 文件
    case kpse_fontmap_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mem` 文件
    case kpse_mem_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mf` 文件
    case kpse_mf_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mfpool` 文件
    case kpse_mfpool_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mft` 文件
    case kpse_mft_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mp` 文件
    case kpse_mp_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mppool` 文件
    case kpse_mppool_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.mpsupport` 文件
    case kpse_mpsupport_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.ocp` 文件
    case kpse_ocp_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.ofm` 文件
    case kpse_ofm_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.opl` 文件
    case kpse_opl_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.otp` 文件
    case kpse_otp_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.ovf` 文件
    case kpse_ovf_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.ovp` 文件
    case kpse_ovp_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.pict` 文件
    case kpse_pict_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.tex` 文件
    case kpse_tex_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 TeX 系统的文档
    case kpse_texdoc_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示一个 `*.texpool` 文件
    case kpse_texpool_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 TeX 系统的源文件
    case kpse_texsource_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 TeX 系统的 Postscript 目录
    case kpse_tex_ps_header_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 troff 类型的文件
    case kpse_troff_font_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 Type1 类型的文件
    case kpse_type1_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.vf` 类型的文件
    case kpse_vf_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `dvips` 的配置文件
    case kpse_dvips_config_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.ist` 类型的文件
    case kpse_ist_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.ttf` 等类型的字体文件
    case kpse_truetype_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 type42 类型的字体文件
    case kpse_type42_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 web2c 系统的相关文件
    case kpse_web2c_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 TeX 系统的文本格式类型的文件
    case kpse_program_text_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 TeX 系统的库文件
    case kpse_program_binary_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 miscfont 类型的文件
    case kpse_miscfonts_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.web` 类型的文件
    case kpse_web_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.cweb` 类型的文件
    case kpse_cweb_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.enc` 类型的文件
    case kpse_enc_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.cmap` 类型的文件
    case kpse_cmap_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.sfd` 类型的文件
    case kpse_sfd_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.otf` 等类型的文件
    case kpse_opentype_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 pdftex 的配置文件
    case kpse_pdftex_config_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.lig` 类型的文件
    case kpse_lig_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 其支持是待做事项的一部分
    case kpse_texmfscripts_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.lua` 类型的文件
    case kpse_lua_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.fea` 类型的文件
    case kpse_fea_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.cid` 类型的文件
    case kpse_cid_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.mlbib` 类型的文件
    case kpse_mlbib_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.mlbst` 类型的文件
    case kpse_mlbst_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.clua` 类型的文件
    case kpse_clua_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.ris` 类型的文件
    case kpse_ris_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 `*.bltxml` 类型的文件
    case kpse_bltxml_format
    /// kpythsea 可搜寻的一种文件类型
    ///
    /// 表示查找对象为 kpathsea 库中该枚举中的最后一个索引
    case kpse_last_format
    
    /// 当前文件类型所对应的所有可能的后缀
    ///
    /// 如果属性的值为空，则表示这种类型的文件尚未受到支持，或者难以支持。
    public var suffix: [String] {
        switch self {
        case .kpse_gf_format:
            return [".gf"]
        case .kpse_pk_format:
            return [".pk"]
        case .kpse_any_glyph_format:
            return [".pk",".gf"]
        case .kpse_tfm_format:
            return [".tfm"]
        case .kpse_afm_format:
            return [".afm"]
        case .kpse_base_format:
            return [".base"]
        case .kpse_bib_format:
            return [".bib"]
        case .kpse_bst_format:
            return [".bst"]
        case .kpse_cnf_format:
            return [".cnf"]
        case .kpse_db_format:
            // 这种不带`.`的情况指的是该文件的文件名就是返回的值
            return ["ls-R","ls-r"]
        case .kpse_fmt_format:
            return [".fmt"]
        case .kpse_fontmap_format:
            return [".map",".fontmap"]
        case .kpse_mem_format:
            return [".mem"]
        case .kpse_mf_format:
            return [".mf"]
        case .kpse_mfpool_format:
            return [".pool"]
        case .kpse_mft_format:
            return [".mft"]
        case .kpse_mp_format:
            return [".mp"]
        case .kpse_mppool_format:
            return [".pool"]
        case .kpse_mpsupport_format:
            return [".ocp",".ofm",".tfm",".opl",".pl",".otp",".ovf",".vf",".ovp",".vpl"]
        case .kpse_ocp_format:
            return [".ocp"]
        case .kpse_ofm_format:
            return [".ofm"]
        case .kpse_opl_format:
            return [".opl"]
        case .kpse_otp_format:
            return [".otp"]
        case .kpse_ovf_format:
            return [".ovf"]
        case .kpse_ovp_format:
            return [".ovp"]
        case .kpse_pict_format:
            return [".eps",".epsi"]
        case .kpse_tex_format:
            return [".tex",".sty",".cls",".fd",".aux",".bbl",".def",".clo",".ldf", ".ltx", ".cfg", ".ini", ".txt"] ///".dat"]
        case .kpse_texdoc_format:
            // 这种格式暂不支持寻找
            return []
        case .kpse_texpool_format:
            return [".pool"]
        case .kpse_texsource_format:
            // 这种格式(TEXSOURCES)暂不支持寻找
            return []
        case .kpse_tex_ps_header_format:
            return [".pro"]
        case .kpse_troff_font_format:
            // 这种格式(TFFONT)暂不支持查找
            return []
        case .kpse_type1_format:
            return [".pfa",".pfb"]
        case .kpse_vf_format:
            return [".vf"]
        case .kpse_dvips_config_format:
            // 例如 `config.ps`
            return ["config."]
        case .kpse_ist_format:
            return [".ist"]
        case .kpse_truetype_format:
            return [".ttf",".TTF",".ttc",".TTC",".dfont"]
        case .kpse_type42_format:
            // 这种格式(T42FONTS)暂不支持查找
            return []
        case .kpse_web2c_format:
            return []
        case .kpse_program_text_format:
            return []
        case .kpse_program_binary_format:
            return []
        case .kpse_miscfonts_format:
            return []
        case .kpse_web_format:
            return [".web",".ch"]
        case .kpse_cweb_format:
            return [".w",".web",".ch"]
        case .kpse_enc_format:
            return [".enc"]
        case .kpse_cmap_format:
            return [".cmap"]
        case .kpse_sfd_format:
            return [".sfd"]
        case .kpse_opentype_format:
            return [".otf",".OTF",".otc",".OTC",".ttf",".TTF",".TTC",".ttc"]
        case .kpse_pdftex_config_format:
            return [".cfg"]
        case .kpse_lig_format:
            return [".lig"]
        case .kpse_texmfscripts_format:
            // tex-mf 中的脚本所在位置，暂不支持查找
            return []
        case .kpse_lua_format:
            return [".lua"]
        case .kpse_fea_format:
            return [".fea"]
        case .kpse_cid_format:
            return [".cid"]
        case .kpse_mlbib_format:
            return [".mlbib"]
        case .kpse_mlbst_format:
            return [".mlbst",".bst"]
        case .kpse_clua_format:
            // 一些动态库，不适用 xetex
            return [".dll",".so"]
        case .kpse_ris_format:
            return [".ris"]
        case .kpse_bltxml_format:
            return [".bltxml"]
        case .kpse_last_format:
            return []
        }
    }
}
