//#region 全局变量定义

const pdfTeX_TYPE = 0;
const XeTeX_TYPE = 1;

/**
 * @var {integer} - 当前设定的引擎类型
 */
let CURRENT_ENGINE_TYPE = null
/**
 * @var {String} - 当前引擎的名称(XeTeX 或者 pdfTeX)
 */
let CURRENT_ENGINE_NAME = null

/**
 * @var {String} - 请求文件或者字体时的网页格式
 */
const FILE_SERVICE_HTTP_POINT = "texengine://"

/**
 *  @var {Number} - 当前 texlive 源文件的版本
 */
const TEXLIVE_VERSION = 2022;

/**
 * @var {Object} - texlive 的 TEXMF 根目录中的文件的缓存字典
 * 
 * - 由于引擎采用虚拟文件系统，在该目录中写入后可以从缓存中尝试再次读取对应路径。
 */
let RESOURCES_TEXLIVE_CACHE = {};

/**
 * @var {Object} - texlive 的 PK 字形字典
 * 
 * 仅供 pdfTeX 使用
 */
let RESOURCES_GLYPH_CACHE = {};

/**
 * @var {Object} - 用户动态文件的缓存字典
 * 
 * - 由于引擎采用虚拟文件系统，在该目录中写入后可以从缓存中尝试再次读取对应路径。在每次编译结束后需要置空本值。
 */
let RESOURCES_DYNAMIC_CACHE = {};

/**
 * @var {Object} - TeX 主文件所在文件夹内的文件的缓存字典。由于引擎采用虚拟文件系统，在该目录中写入后可以从缓存中直接读取对应路径。在每次编译结束后需要置空本值。
 */
let RESOURCES_PROJECT_CACHE = {};


/**
 * @var {String} - 当前的控制台输出内容
 */
let CONSOLE_OUTPUT = ""


class TEX_RETURN_CODE_TYPE  {
    constructor(value) {
        this.value = value
    }
    isNormalError() {
        return (this.value > 0)&&(this.value <= 10)
    }
    value() {
        return this.value
    }
    isEqual(value) {
        return this.value == value
    }
    isEqualObject(object) {
        return this.value == object.value
    }
    isFatalError() {
        return this.isEqualObject(TEX_RETURN_CODE_TYPE.FILE_EXIT) || this.isEqualObject(TEX_RETURN_CODE_TYPE.MEMORY_EXIT) || this.isEqualObject(TEX_RETURN_CODE_TYPE.INTERNAL_EXIT)
    }
}
TEX_RETURN_CODE_TYPE.FILE_EXIT = new TEX_RETURN_CODE_TYPE(-100);
TEX_RETURN_CODE_TYPE.MEMORY_EXIT = new  TEX_RETURN_CODE_TYPE(-200)
TEX_RETURN_CODE_TYPE.INTERNAL_EXIT = new TEX_RETURN_CODE_TYPE(-300)
TEX_RETURN_CODE_TYPE.NO_DVI_EXIT = new TEX_RETURN_CODE_TYPE(1000)
TEX_RETURN_CODE_TYPE.NO_PDF_EXIT = new TEX_RETURN_CODE_TYPE(2000)
TEX_RETURN_CODE_TYPE.SUCCESS = new TEX_RETURN_CODE_TYPE(0)