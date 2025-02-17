#define EXTERN /* Instantiate data from pdftexd.h here.  */

#include <pdftexd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/time.h>
#include <time.h>
#include <errno.h>
#include <md5.h>
#include <setjmp.h>
#include "bibtex.h"
#include <pdftexdir/pdftexextra.h>
#include "uexit.h"
#include <stdbool.h>
#ifdef exit
#undef exit
#endif

#define IS_FILE_PATH_ACCESS(a) ((access(a, F_OK) == 0))
#define IS_FILE_PATH_NOT_ACCESS(a) ((access(a, F_OK) != 0))

#define MAXMAINFILENAME 2048
#define DIGEST_SIZE 16
#define FILE_BUF_SIZE 1024

extern void kpse_set_pdftex_engine_js(void);
char *get_new_file_name_without_extension(const char *file_name);
void engine_delete_file(const char *path);
char *engine_get_cwd(void);
int go_to_mainbody(void);


string fullnameoffile;
string output_directory;

int ac;
char **av;
int tfmtemp;
int texinputtype;
int kpse_make_tex_discard_errors;
string translate_filename;
const_string c_job_name;
char start_time_str[32];
char *last_source_name;
int last_lineno;
static char *cstrbuf = NULL;
static int allocsize;
const char *ptexbanner = BANNER;
char *DEFAULT_FMT_NAME = " pdftex.fmt"; /// 起始有一个空格
char *DEFAULT_DUMP_NAME = "pdftex";
string versionstring = " (TeX Live 2023) Modified version for running on iOS.\n";
int exit_code;
jmp_buf jmpenv;
bool did_set_jmpenv = false;
char *main_entry_file = NULL;
char *bootstrapcmd = NULL;



#define MAX_CSTRING_LEN 1024 * 1024
char *makecstring(integer s) {

  char *p;

  int allocgrow, i, l = strstart[s + 1] - strstart[s];
  if ((unsigned)(l + 1) > (unsigned)(MAX_CSTRING_LEN)) {
    fprintf(stderr, "buffer overflow at file %s, line %d", __FILE__, __LINE__);
    abort();
  }

  if (cstrbuf == NULL) {
    allocsize = l + 1;
    cstrbuf = xmallocarray(char, allocsize);
  } else if (l + 1 > allocsize) {
    allocgrow = allocsize * 0.2;
    if (l + 1 - allocgrow > allocsize)
      allocsize = l + 1;
    else if (allocsize < MAX_CSTRING_LEN - allocgrow)
      allocsize += allocgrow;
    else
      allocsize = MAX_CSTRING_LEN;
    cstrbuf = xreallocarray(cstrbuf, char, allocsize);
  }
  p = cstrbuf;
  for (i = 0; i < l; i++)
    *p++ = strpool[i + strstart[s]];
  *p = 0;
  return cstrbuf;
}

int runsystem(const char *noused) { return 0; }

void topenin(void) {
    int i = 0;
  buffer[first] = 0;
  char *ptr = bootstrapcmd;
  int k = first;
  while (*ptr) {
    buffer[k++] = *(ptr++);
  }
  buffer[k++] = ' ';
  buffer[k] = 0;
  bootstrapcmd[0] = 0;
  for (last = first; buffer[last]; ++last) {}
  #define IS_SPC_OR_EOL(c) ((c) == ' ' || (c) == '\r' || (c) == '\n')
//   for (--last; last >= first && IS_SPC_OR_EOL (buffer[last]); --last) {
//     last++;
//   }
//   for (i = first; i < last; i++)
//     buffer[i] = xord[buffer[i]];
//上面不好用, 因为我们不需要解析相应命令.
  
}

void get_seconds_and_micros(integer *seconds, integer *micros) {

  struct timeval tv;
  gettimeofday(&tv, NULL);
  *seconds = tv.tv_sec;
  *micros = tv.tv_usec;
}

void maketimestr(char *time_str) {
  time_t start_time = time((time_t *)NULL);
  struct tm lt;
  lt = *localtime(&start_time);
  size_t size = strftime(time_str, 31, "D:%Y%m%d%H%M%S", &lt);

  if (size == 0) {
    time_str[0] = '\0';
    return;
  }

  if (time_str[14] == '6') {
    time_str[14] = '5';
    time_str[15] = '9';
    time_str[16] = '\0'; /* for safety */
  }

  time_str[size++] = 'Z';
  time_str[size] = 0;
}

void initstarttime() {
  if (start_time_str[0] == '\0') {
    maketimestr(start_time_str);
  }
}

void convertStringToHexString(const char *in, char *out, int lin) {
  int i, j, k;
  char buf[3];
  j = 0;
  for (i = 0; i < lin; i++) {
    k = snprintf(buf, sizeof(buf), "%02X", (unsigned int)(unsigned char)in[i]);
    out[j++] = buf[0];
    out[j++] = buf[1];
  }
  out[j] = '\0';
}


void
calledit (packedASCIIcode *filename, poolpointer fnstart, integer fnlength, integer linenumber)
{
  char *temp, *command, *fullcmd;
  char c;
  int sdone, ddone;
  sdone = ddone = 0;
  filename += fnstart;
 {  
  int is_ptr; /* element of input_stack, 0 < input_ptr */  
  for (is_ptr = 0; is_ptr < inputptr; is_ptr++) {
    if (inputstack[is_ptr].statefield == 0 /* token list */
        || inputstack[is_ptr].namefield <= 255) { /* can't be filename */
    } else {
      FILE *f;
      /* when name_field > 17, index_field specifies the element of
         the input_file array, 1 <= in_open */
      int if_ptr = inputstack[is_ptr].indexfield;
      if (if_ptr < 1 || if_ptr > inopen) {
        fprintf (stderr, "%s:calledit: unexpected if_ptr=%d not in range 1..%d,",
                 kpse_get_invocation_name_js(), if_ptr, inopen);
        fprintf (stderr, "from input_stack[%d].namefield=%d\n",
                 is_ptr, inputstack[is_ptr].namefield);
        uexit (1);
      }
      
#ifdef XeTeX
      f = inputfile[if_ptr]->f;
#else
      f = inputfile[if_ptr];
#endif
      /* Although it should never happen, if the file value happens to
         be zero, let's not gratuitously abort.  */
      if (f) {
        xfclose (f, "inputfile");
      } else {
        fprintf (stderr, "%s:calledit: not closing unexpected zero", kpse_get_invocation_name_js());
        fprintf (stderr, " input_file[%d] from input_stack[%d].namefield=%d\n",
                 if_ptr, is_ptr, inputstack[is_ptr].namefield);        
      }
    } /* end name_field > 17 */
  }   /* end for loop for input_stack */
 }    /* end block for variable declarations */
 //MARK: - 中间省略了一些外部命令的调用.
  /* Quit, since we found an error.  */
  uexit (1);
}


void get_date_and_time(integer *minutes, integer *day, integer *month,
                       integer *year) {
  struct tm *tmptr;

  /* whether the envvar was not set (usual case) or invalid,
     use current time.  */
  time_t myclock = time((time_t *)0);
  tmptr = localtime(&myclock);

  *minutes = tmptr->tm_hour * 60 + tmptr->tm_min;
  *day = tmptr->tm_mday;
  *month = tmptr->tm_mon + 1;
  *year = tmptr->tm_year + 1900;
}

strnumber getjobname(strnumber name) {
  strnumber ret = name;
  if (c_job_name != NULL)
    ret = maketexstring(c_job_name);
  return ret;
}

strnumber makefullnamestring(void) { return maketexstring(fullnameoffile); }

strnumber makeinputoutputnamestring(void) {
  return maketexstring(nameoffile + 1);
}

char *makecfilename(integer s) {
  char *name = makecstring(s);
  char *p = name;
  char *q = name;

  while (*p) {
    if (*p != '"')
      *q++ = *p;
    p++;
  }
  *q = '\0';
  return name;
}

void getcreationdate(void) {
  size_t len;

  initstarttime();
  /* put creation date on top of string pool and update poolptr */
  len = strlen(start_time_str);
  if ((unsigned)(poolptr + len) >= (unsigned)(poolsize)) {
    poolptr = poolsize;
    /* error by str_toks that calls str_room(1) */
    return;
  }
  memcpy(&strpool[poolptr], start_time_str, len);
  poolptr += len;
}

void getfilemoddate(integer s) {
  struct stat file_data;

  const_string orig_name = makecfilename(s);

  char *file_name = kpse_find_tex(orig_name);
  if (file_name == NULL) {
    return; /* empty string */
  }
  if (!kpse_in_name_ok(file_name)) {
    return; /* no permission */
  }

  recorder_record_input(file_name);
  /* get file status */

  if (stat(file_name, &file_data) == 0) {

    size_t len;
    char time_str[32];
    maketimestr(time_str);
    len = strlen(time_str);
    if ((unsigned)(poolptr + len) >= (unsigned)(poolsize)) {
      poolptr = poolsize;
      /* error by str_toks that calls str_room(1) */
    } else {
      memcpy(&strpool[poolptr], time_str, len);
      poolptr += len;
    }
  }
  /* else { errno contains error code } */

  free(file_name);
}

void getfilesize(integer s) {
  struct stat file_data;
  int i;

  char *file_name = kpse_find_tex(makecfilename(s));

  if (file_name == NULL) {
    return; /* empty string */
  }
  if (!kpse_in_name_ok(file_name)) {
    return; /* no permission */
  }

  recorder_record_input(file_name);
  /* get file status */

  if (stat(file_name, &file_data) == 0) {

    size_t len;
    char buf[20];
    /* st_size has type off_t */
    i = snprintf(buf, sizeof(buf), "%lu", (long unsigned int)file_data.st_size);
    len = strlen(buf);
    if ((unsigned)(poolptr + len) >= (unsigned)(poolsize)) {
      poolptr = poolsize;
      /* error by str_toks that calls str_room(1) */
    } else {
      memcpy(&strpool[poolptr], buf, len);
      poolptr += len;
    }
  }
  /* else { errno contains error code } */

  free(file_name);
}



void getmd5sum(strnumber s, boolean file) {
  md5_state_t state;
  md5_byte_t digest[DIGEST_SIZE];
  char outbuf[2 * DIGEST_SIZE + 1];
  int len = 2 * DIGEST_SIZE;

  if (file) {
    char file_buf[FILE_BUF_SIZE];
    int read = 0;
    FILE *f;
    char *file_name;

    file_name = kpse_find_tex(makecfilename(s));

    if (file_name == NULL) {
      return; /* empty string */
    }
    if (!kpse_in_name_ok(file_name)) {
      return; /* no permission */
    }

    /* in case of error the empty string is returned,
       no need for xfopen that aborts on error.
     */
    f = fopen(file_name, FOPEN_RBIN_MODE);
    if (f == NULL) {
      free(file_name);
      return;
    }
    recorder_record_input(file_name);
    md5_init(&state);
    while ((read = fread(&file_buf, sizeof(char), FILE_BUF_SIZE, f)) > 0) {
      md5_append(&state, (const md5_byte_t *)file_buf, read);
    }
    md5_finish(&state, digest);
    fclose(f);

    free(file_name);
  } else {
    /* s contains the data */
    md5_init(&state);

    md5_append(&state, (md5_byte_t *)&strpool[strstart[s]],
               strstart[s + 1] - strstart[s]);
    md5_finish(&state, digest);
  }

  if (poolptr + len >= poolsize) {
    /* error by str_toks that calls str_room(1) */
    return;
  }
  convertStringToHexString((char *)digest, outbuf, DIGEST_SIZE);

  memcpy(&strpool[poolptr], outbuf, len);
  poolptr += len;
}

void getfiledump(integer s, int offset, int length) {
  FILE *f;
  int read, i;
  poolpointer data_ptr;
  poolpointer data_end;
  char *file_name;

  if (length == 0) {
    /* empty result string */
    return;
  }

  if (poolptr + 2 * length + 1 >= poolsize) {
    /* no place for result */
    poolptr = poolsize;
    /* error by str_toks that calls str_room(1) */
    return;
  }

  file_name = kpse_find_tex(makecfilename(s));
  if (file_name == NULL) {
    return; /* empty string */
  }
  if (!kpse_in_name_ok(file_name)) {
    return; /* no permission */
  }

  /* read file data */
  f = fopen(file_name, FOPEN_RBIN_MODE);
  if (f == NULL) {
    free(file_name);
    return;
  }
  recorder_record_input(file_name);
  if (fseek(f, offset, SEEK_SET) != 0) {
    free(file_name);
    return;
  }

  /* there is enough space in the string pool, the read
     data are put in the upper half of the result, thus
     the conversion to hex can be done without overwriting
     unconverted bytes. */
  data_ptr = poolptr + length;
  read = fread(&strpool[data_ptr], sizeof(char), length, f);
  fclose(f);

  /* convert to hex */
  data_end = data_ptr + read;
  for (; data_ptr < data_end; data_ptr++) {
    i = snprintf((char *)&strpool[poolptr], 3, "%.2X",
                 (unsigned int)strpool[data_ptr]);

    poolptr += i;
  }

  free(file_name);
}

string gettexstring(strnumber s) {
  poolpointer len;
  string name;
  len = strstart[s + 1] - strstart[s];
  name = (string)xmalloc(len + 1);
  strncpy(name, (string)&strpool[strstart[s]], len);
  name[len] = 0;
  return name;
}

static int compare_paths(const_string p1, const_string p2) {
  int ret;
  while ((((ret = (*p1 - *p2)) == 0) && (*p2 != 0))

         || (IS_DIR_SEP(*p1) && IS_DIR_SEP(*p2))) {
    p1++, p2++;
  }
  ret = (ret < 0 ? -1 : (ret > 0 ? 1 : 0));
  return ret;
}

boolean isnewsource(strnumber srcfilename, int lineno) {
  char *name = gettexstring(srcfilename);
  return (compare_paths(name, last_source_name) != 0 || lineno != last_lineno);
}

void remembersourceinfo(strnumber srcfilename, int lineno) {
  if (last_source_name) {
    free(last_source_name);
  }
  last_source_name = gettexstring(srcfilename);
  last_lineno = lineno;
}

poolpointer makesrcspecial(strnumber srcfilename, int lineno) {
  poolpointer oldpoolptr = poolptr;
  char *filename = gettexstring(srcfilename);
  /* FIXME: Magic number. */
  char buf[40];
  char *s = buf;

  /* Always put a space after the number, which makes things easier
   * to parse.
   */
  sprintf(buf, "src:%d ", lineno);

  if (poolptr + strlen(buf) + strlen(filename) >= (size_t)poolsize) {
    fprintf(stderr, "\nstring pool overflow\n"); /* fixme */
    uexit(1);
  }
  s = buf;
  while (*s)
    strpool[poolptr++] = *s++;

  s = filename;
  while (*s)
    strpool[poolptr++] = *s++;

  return (oldpoolptr);
}

void uexit(int code) {
  exit_code = code;
  if (!did_set_jmpenv) {
    exit(code);
  }
  longjmp(jmpenv, 1);
}

boolean
texmfyesno(const_string var)
{
  return 0;
}

string
find_input_file(integer s)
{
    string filename;


    filename = makecfilename(s);
    /* Look in -output-directory first, if the filename is not
       absolute.  This is because we want the pdf* functions to
       be able to find the same files as \openin */
    if (output_directory && !kpse_absolute_p (filename, false)) {
        string pathname;

        pathname = concat3(output_directory, DIR_SEP_STRING, filename);
        if (!access(pathname, R_OK) && !dir_p (pathname)) {
            return pathname;
        }
        xfree (pathname);
    }
    return kpse_find_tex(filename);
}




/// @brief 根据指定的格式文件的名称，编译某个 tex 文件。
/// @param entry_name 主文件的名称，如 `123.tex`，不需要带引号！。
/// @param work_dir_path 主文件所在文件夹的路径。例如 `/Users/project`。
/// @param fmt_name 使用的 fmt 文件的名称(带扩展名)，如 `pdflate.fmt`。
/// @return 返回编译结果指示值。如果引擎虽然编译了但是没有 pdf 文件的输出，返回 2000；如果发生了期望以外的错误(没有任何输出, 甚至没有成功调用引擎)，返回 -1。除了以上情况以外，如果引擎没有报错，返回 0，否则返回 1 (和XeTeX不同, 这里不会返回3, 但是还是可以一起处理)。
int engine_compile_tex(const char *entry_name, const char *work_dir_path, const char *fmt_name)
{
    /// 设置 fmt 名称
    DEFAULT_DUMP_NAME = NULL;
    DEFAULT_FMT_NAME = concat3_noexit(" ", fmt_name, NULL);
    RETURN_IF_NULL_MALLOC_POINTER(DEFAULT_DUMP_NAME);
    char *fmtDumpName = get_new_file_name_without_extension(fmt_name);
    RETURN_IF_NULL_MALLOC_POINTER(fmtDumpName);
    /// 设置 dump 名称
    DEFAULT_DUMP_NAME = NULL;
    DEFAULT_DUMP_NAME = malloc(strlen(fmtDumpName) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(DEFAULT_DUMP_NAME);
    strcpy(DEFAULT_DUMP_NAME, fmtDumpName);
    /* 设置入口文件 */
    char *main_entry_file = concat3_noexit("\"", entry_name, "\"");
    RETURN_IF_NULL_MALLOC_POINTER(main_entry_file);
    bootstrapcmd = NULL;
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
    RETURN_IF_NULL_MALLOC_POINTER(new_dir_with_backslash);
    RETURN_IF_NULL_MALLOC_POINTER(tex_name_no_extension);
    char *tex_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".tex");
    char *log_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".log");
    char *pdf_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".pdf");
    char *synctex_path = concat3_noexit(new_dir_with_backslash, tex_name_no_extension, ".synctex");
    RETURN_IF_NULL_MALLOC_POINTER(synctex_path);
#ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[TeX Engine Internal]: 当前 pdf 文件的预计路径为 %s\n", pdf_path);
#endif
    engine_delete_file(tex_path);
    engine_delete_file(log_path);
    engine_delete_file(pdf_path);
    engine_delete_file(synctex_path);
    clock_t start, end;
    double mainbody_used;
    start = clock();
    int backValue = go_to_mainbody(); /// 这里有可能永远不返回, 这时候在 JS 端会抛出错误.
    end = clock();
    mainbody_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    #ifdef WEBASSEMBLY_DEBUG
    printf("\n[TeX Engine Internal][tex_to_pdf] 运行时长: %f s\n", mainbody_used);
    #endif
    if (backValue == KPSE_MEMORY_EXIT_CODE) {
        fprintf(stderr, "\nMemory allocate failured. Aborted.\n");
        return KPSE_MEMORY_EXIT_CODE; /// 内部错误, 进程被终止, 此时可以理解为引擎崩溃了
    } else if (backValue == KPSE_FILE_EXIT_CODE) {
        fprintf(stderr, "\nFile access failured. Aborted.\n");
        return KPSE_FILE_EXIT_CODE;
    } else if (backValue == KPSE_TEX_INTERNAL_EXIT_CODE) {
        fprintf(stderr, "\nFatal Internal Error Occurred. Aborted.\n");
        return KPSE_TEX_INTERNAL_EXIT_CODE;
    }
    if (IS_FILE_PATH_NOT_ACCESS(pdf_path))
    {
#ifdef WEBASSEMBLY_DEBUG
        fprintf(stderr, "[TeX Engine Internal]: 未能生成 pdf 文件.\n");
#endif
        return KPSE_TEX_NO_PDF_OUTPUT;
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
    fprintf(stdout, "init_file_name = %s\n", init_file_name);
    fprintf(stdout, "output_dir_path = %s\n", output_dir_path);
    /* 设置 fmt 名称 */
    char *fmtDumpName = get_new_file_name_without_extension(init_file_name);
    DEFAULT_DUMP_NAME = NULL;
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
    bootstrapcmd = NULL;
    bootstrapcmd = malloc(strlen(newName) + 1);
    RETURN_IF_NULL_MALLOC_POINTER(bootstrapcmd);
    strcpy(bootstrapcmd, newName);
    chdir(output_dir_path);
    return go_to_mainbody();
}

/**
 * 使用 bibtex 进行编译
 * @param entry_name: 扩展名为 `aux` 的文件，例如 `texfileName.aux`。它通常与 `tex` 文件的名称相同。
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



int main(int argc, char **argv) {
    kpse_set_pdftex_engine_js();
    #ifdef WEBASSEMBLY_DEBUG
    fprintf(stderr, "[pdfTeX: Engine Loaded!]\n");
    #endif
}

/// 返回: <=-100, 0, 1
int go_to_mainbody(void) {
    if (setjmp(jmpenv) == 0) {
    did_set_jmpenv = true;
    haltonerrorp = 1;
    dumpname = DEFAULT_DUMP_NAME;
    int fmtstrlen = strlen(DEFAULT_FMT_NAME);
    TEXformatdefault = xmalloc(fmtstrlen + 2);
    memcpy(TEXformatdefault, DEFAULT_FMT_NAME, fmtstrlen);
    formatdefaultlength = strlen(TEXformatdefault + 1);
    interactionoption = 1;
    filelineerrorstylep = 1;
    parsefirstlinep = 0;
    maxprintline = 300;
    errorline = 254;
    halferrorline = 238;
    // synctex, 我们不使用压缩
    synctexoption = -1;
    exit_code = KPSE_TEX_INTERNAL_EXIT_CODE;
    // Go
    mainbody(); /* -100(aborted), 0, 1 */
    did_set_jmpenv = false;
    return exit_code;
    } else {
        did_set_jmpenv = false;
        return KPSE_TEX_INTERNAL_EXIT_CODE;
    }
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
    if (!path) {
        return;
    }
    if (IS_FILE_PATH_ACCESS(path)) {
        remove(path);
    }
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
        if (!new_file_name) { return NULL; };
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
