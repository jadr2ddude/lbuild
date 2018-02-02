#define _GNU_SOURCE
#include<sys/prctl.h>
#include<sys/stat.h>
#include<sys/wait.h>
#include<unistd.h>
#include<stdlib.h>
#include<signal.h>
#include<stdbool.h>
#include<errno.h>
#include<stdio.h>
#include<string.h>
#include<time.h>

//fork/exec with child set to sudoku when the parent dies
pid_t lbuild_util_fexec(char *const argv[]) {
    int fret = fork();
    switch(fret) {
    case -1:
        return -1;
    case 0:
        //prctl(PR_SET_PDEATHSIG, SIGKILL);
        execvpe(argv[0], argv, environ);
        printf("Exec fail: %s\n", strerror(errno));
        exit(65);
    default:
        return fret;
    }
}

int lbuild_util_isNewer(const char *a, const char *b) {
    struct stat sa, sb;
    if(stat(a, &sa) != 0) {
        return -1;
    }
    if(stat(b, &sb) != 0) {
        return -1;
    }
    if(difftime(sa.st_mtime, sb.st_mtime) > 0) {
        return 1;
    }
    return 0;
}

bool exists(const char path[]) {
    return access(path, R_OK) == 0;
}

struct wpid_result {
    pid_t pid;
    int exitcode;
};

struct wpid_result wpid() {
    struct wpid_result res;
    int status;
    res.pid = waitpid(-1, &status, 0);
    res.exitcode = WEXITSTATUS(status);
    return res;
}
