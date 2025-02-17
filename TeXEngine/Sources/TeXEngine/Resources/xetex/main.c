#define EXTERN // 实例化来自 `pdftexd.h` 的数据

#include <xetexd.h>
#include "synctexdir/synctex-common.h"
#include <errno.h>
#include <md5.h>
#include <setjmp.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include <stdbool.h>
#include "bibtex.h"
#include "libdpx/dvipdfmx-wasm.h"
#include <xetexdir/xetexextra.h>
#include "uexit.h"
#ifdef exit
#undef exit
#endif

#define IS_FILE_PATH_ACCESS(a) ((access(a, F_OK) == 0))
#define IS_FILE_PATH_NOT_ACCESS(a) ((access(a, F_OK) != 0))


int ac;
char **av;

const char *ptexbanner = BANNER;
string versionstring = " (TeX Live 2023) This version has been modified for running on iOS or iPadOS.";
char *bootstrapcmd = NULL;
int exit_code = 0;
jmp_buf jmpenv;
bool did_set_jmpenv = false;

extern void kpse_set_xetex_engine_js(void);
char *get_new_file_name_without_extension(const char *file_name);
void engine_delete_file(const char *path);
int engine_compile_tex(const char *entry_name, const char *work_dir_path, const char *fmt_name);
int engine_compile_tex_to_xdv(const char *entry_name, const char *work_dir_path, const char *fmt_name);
int engine_compile_tex_fmt(const char *init_file_name, const char *output_dir_path);
char *engine_get_cwd(void);
/**
 * 表示读取的格式文件的文件名称, 例如 ` xelatex.fmt`
 * 必须以空格开头
 */
char *DEFAULT_FMT_NAME = " xetex.fmt";
/**
 * 表示读取的格式文件的展示名(仅用于展示, 没有其它任何作用)
 * 例如 `xelatex`
 */
char *DEFAULT_DUMP_NAME = "xetex";

int go_to_mainbody(void);

/// @brief 根据指定的格式文件的名称，编译某个 tex 文件。
/// @param entry_name 主文件的名称，如 `123.tex`，不需要带引号！。
/// @param work_dir_path 主文件所在文件夹的路径。例如 `/Users/project`。
/// @param fmt_name 使用的 fmt 文件的名称(带扩展名)，如 `xelate.fmt`。
/// @return 返回编译结果指示值。如果引擎虽然编译了但是没有 xdv 文件的输出，返回 1000；如果引擎缩入编译了但是没有 pdf 文件的输出，返回 2000；如果发生了期望以外的错误(没有任何输出, 甚至没有成功调用引擎)，返回 -1。除了以上情况以外，如果引擎没有报错，返回 0，否则返回  1 或者 3。
int engine_compile_tex(const char *entry_name, const char *work_dir_path, const char *fmt_name)
{
    clock_t start, middle, end;
    double mainbody_used, dpx_used;
    start = clock();
    int backValue = engine_compile_tex_to_xdv(entry_name, work_dir_path, fmt_name);
    middle = clock();
    if ((backValue <= -1 ) || (backValue == KPSE_TEX_NO_DVI_OUTPUT)) {
        return backValue;
    }
    char *current_dir = engine_get_cwd(); /*已经在上边的调用中设置工作目录了*/
    if (!current_dir) {
        return KPSE_FILE_EXIT_CODE;
    }
    char *new_dir_with_backslash = concat3_noexit(current_dir, "/", NULL);
    char *tex_name_no_extension = get_new_file_name_without_extension(entry_name);
    char *pdf_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".pdf");
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[TeX Engine Internal][dpx] 当前 pdf 文件的预计路径为 %s\n", pdf_path);
#endif
    if (IS_FILE_PATH_ACCESS(pdf_path))
    {
        remove(pdf_path);
    }
    mainbody_used = ((double)(middle - start)) / CLOCKS_PER_SEC;
#ifdef WEBASSEMBLY_DEBUG
    printf("\n[TeX Engine Internal][tex_to_xdv] 运行时长: %f s\n", mainbody_used);
#endif
    dpx_convert_xdv_to_pdf(concat3_noexit(tex_name_no_extension, ".xdv", NULL));
    end = clock();
    dpx_used = ((double)(end - middle)) / CLOCKS_PER_SEC;
#ifdef WEBASSEMBLY_DEBUG
    printf("\n[TeX Engine Internal][libdpx] 转换时长: %f\n", dpx_used);
#endif
    if (IS_FILE_PATH_NOT_ACCESS(pdf_path))
    {
#ifdef WEBASSEMBLY_DEBUG
        fprintf(stderr, "[TeX Engine Internal]: 未能生成 pdf 文件.\n");
#endif
        return KPSE_TEX_NO_PDF_OUTPUT;
    }
    return backValue;
}

/// @brief  根据指定的格式文件的名称，编译某个 tex 文件。
/// @param entry_name 主文件的名称，如 `123.tex`，不需要带引号！。
/// @param work_dir_path 主文件所在文件夹的路径。例如 `/Users/project`。
/// @param fmt_name 使用的 fmt 文件的名称(带扩展名)，如 `xelate.fmt`。
/// @return 返回 mainbody 的值。特别地，如果没有 xdv 文件输出，返回 1000；如果发生了期望以外的错误(没有任何输出, 甚至没有成功调用引擎)，返回 -1；如果引擎没有报错，返回 0，否则返回 1 或者 2。
int engine_compile_tex_to_xdv(const char *entry_name, const char *work_dir_path, const char *fmt_name)
{
    /* 设置 fmt 文件名*/
    DEFAULT_DUMP_NAME = NULL;
    DEFAULT_FMT_NAME = concat3_noexit(" ", fmt_name, NULL); // 前面要有一个空格, 因为 TeX 读取指针的后一个位置

#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[DEFAULT_FMT_NAME] [%s]\n", DEFAULT_FMT_NAME);
#endif
    /* 设置 dump 名称*/
    char *fmtDumpName = get_new_file_name_without_extension(fmt_name);
    RETURN_IF_NULL_MALLOC_POINTER(fmtDumpName);
    DEFAULT_DUMP_NAME = malloc(strlen(fmtDumpName) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(DEFAULT_DUMP_NAME);
    strcpy(DEFAULT_DUMP_NAME, fmtDumpName);
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[DEFAULT_DUMP_NAME] [%s]\n", DEFAULT_DUMP_NAME);
#endif
    /* 设置入口文件 */
    char *main_entry_file = concat3_noexit("\"", entry_name, "\"");
    bootstrapcmd = malloc(strlen(main_entry_file) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(bootstrapcmd);
    strcpy(bootstrapcmd, main_entry_file);
    chdir(work_dir_path);
    char *current_dir = engine_get_cwd();
    if (!current_dir)
    {
#ifdef WEBASSEMBLY_DEBUG
        fprintf(stderr, "[TeX Engine Internal]: 工作目录设置失败! 待设置值为 %s\n 正在终止...\n", work_dir_path);

#endif
        return KPSE_FILE_EXIT_CODE; /*内部错误*/
    }
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[TeX Engine Internal]: 当前工作目录为 %s\n", current_dir);
#endif
    char *new_dir_with_backslash = concat3_noexit(current_dir, "/", NULL);
    char *tex_name_no_extension = get_new_file_name_without_extension(entry_name);
    RETURN_IF_NULL_MALLOC_POINTER(tex_name_no_extension);
    char *tex_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".tex");
    char *xdv_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".xdv");
    char *log_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".log");
    //char *pdf_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".pdf");
    char *synctex_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".synctex");
    RETURN_IF_NULL_MALLOC_POINTER(tex_path);
    RETURN_IF_NULL_MALLOC_POINTER(xdv_path);
    RETURN_IF_NULL_MALLOC_POINTER(log_path);
    RETURN_IF_NULL_MALLOC_POINTER(synctex_path);
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[TeX Engine Internal]: 当前 xdv 文件的预计路径为 %s\n", xdv_path);
#endif
    engine_delete_file(tex_path);
    engine_delete_file(xdv_path);
    engine_delete_file(log_path);
    //engine_delete_file(pdf_path);
    engine_delete_file(synctex_path);
    clock_t start, end;
    double mainbody_used;
    start = clock();
    int backValue = go_to_mainbody();
    end = clock();
    mainbody_used = ((double)(end - start)) / CLOCKS_PER_SEC;
#ifdef WEBASSEMBLY_DEBUG
    printf("\n[main_body tex_to_xdv] 运行时长: %f s, 返回值: %d\n", mainbody_used, backValue);
#endif

    if (backValue == KPSE_MEMORY_EXIT_CODE) {
        fprintf(stdout, "\n...Memory allocate failured. Aborted.\n");
        return KPSE_MEMORY_EXIT_CODE; /// 内部错误, 进程被终止, 此时可以理解为引擎崩溃了
    } else if (backValue == KPSE_FILE_EXIT_CODE) {
        fprintf(stdout, "\n...File access failured. Aborted.\n");
        return KPSE_FILE_EXIT_CODE;
    } else if (backValue == KPSE_TEX_INTERNAL_EXIT_CODE) {
        fprintf(stdout, "\n... Fatal Internal Error Occurred. Aborted.\n");
        return KPSE_TEX_INTERNAL_EXIT_CODE;
    }
    if (IS_FILE_PATH_NOT_ACCESS(xdv_path))
    {
#ifdef WEBASSEMBLY_DEBUG
        fprintf(stderr, "[TeX Engine Internal]: 未能生成 xdv 文件.\n");
#endif
        return KPSE_TEX_NO_DVI_OUTPUT;
    }
    return backValue;
}



/**
 * 编译格式文件(INITEX)
 * @param init_file_name: 初始化文件的名称, 例如 `xelatex.ini`。传入的文件必须以 `ini` 为扩展名。
 * @param output_dir_path: 输出的格式文件所在的文件夹的路径。
 * @return 返回 mainbody 执行后的返回值。
 */
int engine_compile_tex_fmt(const char *init_file_name, const char *output_dir_path)
{
    /* 设置 fmt 名称 */
    char *fmtDumpName = get_new_file_name_without_extension(init_file_name);
    RETURN_IF_NULL_MALLOC_POINTER(fmtDumpName);
    DEFAULT_DUMP_NAME = malloc(strlen(fmtDumpName) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(DEFAULT_DUMP_NAME);
    strcpy(DEFAULT_DUMP_NAME, fmtDumpName);
    DEFAULT_FMT_NAME = concat3_noexit(" ", fmtDumpName, ".fmt");
    RETURN_IF_NULL_MALLOC_POINTER(DEFAULT_FMT_NAME);
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[DEFAULT_DUMP_NAME] [%s]\n", DEFAULT_DUMP_NAME);
    fprintf(stderr, "[DEFAULT_FMT_NAME] [%s]\n", DEFAULT_FMT_NAME);
#endif
    /* 配置环境值 */
    iniversion = 1; /* 设置此环境值将配置 xetex 内部为 INITEX 状态 */
    char *newName = concat3_noexit("*", init_file_name, NULL);
    RETURN_IF_NULL_MALLOC_POINTER(newName);
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[bootstrcapcmd]: %s\n\n", newName);
#endif
    bootstrapcmd = malloc(strlen(newName) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(bootstrapcmd);
    strcpy(bootstrapcmd, newName);
    chdir(output_dir_path);
    return go_to_mainbody();
}



/**
 * 调用 TeX 引擎实际执行编译
 * @return 返回值只可能是 `-1000,-2000,-3000, 0,1,3`。`0` 表示没有错误，其它值表示出现错误。
 */
int go_to_mainbody()
{
    if (setjmp(jmpenv) == 0)
    {
        did_set_jmpenv = true;
    // haltonerrorp = 0;
    dumpname = DEFAULT_DUMP_NAME;
    int fmtstrlen = strlen(DEFAULT_FMT_NAME);
    TEXformatdefault = xmalloc(fmtstrlen + 2);
    memcpy(TEXformatdefault, DEFAULT_FMT_NAME, fmtstrlen);
    formatdefaultlength = strlen(TEXformatdefault + 1);
    nopdfoutput = 1;
    interactionoption = 1;
    filelineerrorstylep = 1;
    parsefirstlinep = 0;
    maxprintline = 300;
    errorline = 254;
    halferrorline = 238;
    // synctex, 我们不使用压缩
    synctexoption = -1;
    exit_code = KPSE_TEX_INTERNAL_EXIT_CODE;
        mainbody();
        /// 注意: mainbody 是 xetex 的内部函数, 但是它不返回任何值。mainbody 在排版出错情形下的返回值代码是通过 uexit 函数实现的。
        did_set_jmpenv = false;
        return exit_code;
    } else {
        did_set_jmpenv = false;
        return exit_code;
    }
    
}

/**
 * 使用 bibtex 进行编译
 * @param entry_name: 扩展名为 `aux` 的文件，例如 `texfileName.aux`。它通常与 `tex` 文件的名称相同。
 * @return 返回整数: -1(内部内存错误), -2(无aux文件错误), -3(无有效blg输出), >=0(常规bibtex错误)
 */
int engine_compile_bibtex(const char *entry_name, const char *work_dir_path)
{
    #define _RETURN_IF_NULL_POINTRT(c) \
    if (c == NULL) { \
        return -1;\
    }
    chdir(work_dir_path);
    char *current_dir = engine_get_cwd();
    _RETURN_IF_NULL_POINTRT(current_dir);
    char *new_dir_with_backslash = concat3_noexit(current_dir, "/", NULL);
    _RETURN_IF_NULL_POINTRT(new_dir_with_backslash);
    char *tex_name_no_extension = get_new_file_name_without_extension(entry_name);
    _RETURN_IF_NULL_POINTRT(tex_name_no_extension);
    char *aux_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".aux");
    char *bbl_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".bbl");
    char *blg_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".blg");
    _RETURN_IF_NULL_POINTRT(aux_path);
    _RETURN_IF_NULL_POINTRT(bbl_path);
    _RETURN_IF_NULL_POINTRT(blg_path);
    remove(bbl_path);
    remove(blg_path);
    const char *aux_file_name = concat3_noexit(tex_name_no_extension, ".aux", NULL);
    _RETURN_IF_NULL_POINTRT(aux_file_name);
    if (IS_FILE_PATH_NOT_ACCESS(aux_path)) {
        return -2; /*此时根本没有aux文件, 无法编译成功.*/
    }
    int return_state = bibtex_main(aux_file_name); /* 0...3, 错误程度依次递增 */
    if (IS_FILE_PATH_ACCESS(blg_path) && IS_FILE_PATH_ACCESS(bbl_path)) {
        return return_state;
    } else if (IS_FILE_PATH_ACCESS(blg_path)) {
        engine_delete_file(bbl_path);
        return return_state; 
    } else { /* 此时根本没有产生有效的 blg 输出 */
        return -3;
    }
    #undef _RETURN_IF_NULL_POINTRT
}

char *engine_get_cwd(void) {
    char *current_dir = getcwd(NULL, 0);
    if (current_dir)
    {
        if (current_dir[strlen(current_dir)] == '/')
        {
            *(current_dir + strlen(current_dir)) = '0';
        }
    }
    return current_dir;
}

/// @brief 调用本函数以尝试移除某个路径下的文件
void engine_delete_file(const char *path)
{
    if (!path) { return; }
    if (IS_FILE_PATH_ACCESS(path)) {
        remove(path);
    }
}

int main(int argc, char **argv)
{
    kpse_set_xetex_engine_js();
    #ifndef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[XeTeX: Engine Loaded!]\n");
    #endif
}

void topenin(void)
{
    static UFILE termin_file;
    if (termin == 0)
    {
        termin = &termin_file;
        termin->f = stdin;
        termin->savedChar = -1;
        termin->skipNextLF = 0;
        termin->encodingMode = UTF8;
        termin->conversionData = 0;
        inputfile[0] = termin;
    }
    buffer[first] = 0;
    // unsigned char* ptr = (unsigned char *)(&bootstrapcmd[0]);
    unsigned char *ptr = (unsigned char *)(bootstrapcmd);
    int k = first;
    /// 我们处理 UTF8 情形下的文件名
    /// 这里修改了原先 SwiftLaTeX 的函数, 使得其支持 UTF 格式的文件名
    UInt32 rval;
    int indexWhile = 0;
    while ((rval = *(ptr++)) != 0)
    {
        indexWhile++;
        UInt16 extraBytes = bytesFromUTF8[rval];
        switch (extraBytes)
        { /* note: code falls through cases! */
        case 5:
            rval <<= 6;
            if (*ptr)
                rval += *(ptr++);
        case 4:
            rval <<= 6;
            if (*ptr)
                rval += *(ptr++);
        case 3:
            rval <<= 6;
            if (*ptr)
                rval += *(ptr++);
        case 2:
            rval <<= 6;
            if (*ptr)
                rval += *(ptr++);
        case 1:
            rval <<= 6;
            if (*ptr)
                rval += *(ptr++);
        case 0:;
        }
        rval -= offsetsFromUTF8[extraBytes];
        buffer[k++] = rval;
    }
    buffer[k++] = ' ';
    buffer[k] = 0;
    // bootstrapcmd[0] = 0;
    for (last = first; buffer[last]; ++last)
    {
    }
#define IS_SPC_OR_EOL(c) ((c) == ' ' || (c) == '\r' || (c) == '\n')
    for (--last; last >= first && IS_SPC_OR_EOL(buffer[last]); --last)
        ;
    last++;
    // printf("BUFFER:\n%d\n", buffer);
}

void uexit(int code)
{
    exit_code = code;
    if (!did_set_jmpenv) {
        exit(code);
    }
    longjmp(jmpenv, 1);
    exit(code);
}

/**
 * 移除某个字符串所代表的文件的扩展名
 * 这将用 `malloc` 申请一块新内存区域
 * @return 如果原值为 `123.tex`，则返回 `123`。
 */
char *get_new_file_name_without_extension(const char *file_name)
{
    if (file_name)
    {
        char *new_file_name = malloc(strlen(file_name) + 1);
        if (!new_file_name) {
            return NULL;
        }
        strcpy(new_file_name, file_name);
        char *dot = strrchr(new_file_name, '.');
        if (dot)
        {
            *dot = '\0';
        }
        return new_file_name;
    }
    return NULL;
}

// #endif
