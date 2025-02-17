#define EXTERN extern
#include <pdftexd.h>

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
#include <uexit.h>

string xgetcwd (void) {
    char path[PATH_MAX + 1];
    if (getcwd (path, PATH_MAX + 1) == NULL) {
        uexit(1);
    }
    return xstrdup (path);
}

char *generic_synctex_get_current_name (void) {
    char *pwdbuf, *ret;
    if (!fullnameoffile) {
        ret = xstrdup("");
        return ret;
    }
    if (kpse_absolute_p(fullnameoffile, false)) {
        return xstrdup(fullnameoffile);
    }
    pwdbuf = xgetcwd();
    ret = concat3(pwdbuf, DIR_SEP_STRING, fullnameoffile);
    free(pwdbuf);
    return ret;
    if (kpse_absolute_p(fullnameoffile, false)) {
        return xstrdup(fullnameoffile);
    }
}


