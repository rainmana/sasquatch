#!/bin/bash
# Apply macOS compatibility fixes to squashfs-tools source

cd squashfs-tools || exit 1

# Fix unsquashfs.c - sysinfo.h and sysmacros.h
sed -i.bak '34s|#include <sys/sysinfo.h>|#ifdef __linux__\n#include <sys/sysinfo.h>\n#include <sys/sysmacros.h>\n#else\n#include <sys/sysctl.h>\n#endif|' unsquashfs.c
sed -i.bak '36s|#include <sys/sysmacros.h>||' unsquashfs.c

# Fix unsquashfs.c - FNM_EXTMATCH
sed -i.bak 's|FNM_PATHNAME|FNM_PERIOD|FNM_EXTMATCH|FNM_PATHNAME|FNM_PERIOD\
#ifdef FNM_EXTMATCH\
\t\t\t\t|FNM_EXTMATCH\
#endif|' unsquashfs.c

# Fix unsquashfs_info.c - signal handling
sed -i.bak '23a\
#define _POSIX_C_SOURCE 200809L\
#ifdef __APPLE__\
#define _DARWIN_C_SOURCE\
#endif\
' unsquashfs_info.c

sed -i.bak 's|struct timespec timespec = { .tv_sec = 1, .tv_nsec = 0 };|#ifndef __APPLE__\
struct timespec timespec = { .tv_sec = 1, .tv_nsec = 0 };\
#endif|' unsquashfs_info.c

sed -i.bak '/while(1) {/,/sig = sigwaitinfo/ {
    /if(waiting)/ i\
#ifdef __APPLE__\
\t\t// macOS does not support sigtimedwait/sigwaitinfo, use sigwait instead\
\t\tint sig_num;\
\t\tif(sigwait(&sigmask, &sig_num) == 0) {\
\t\t\tsig = sig_num;\
\t\t} else {\
\t\t\tsig = -1;\
\t\t}\
#else
    /sig = sigwaitinfo/s/$/\
#endif/
}' unsquashfs_info.c

# Fix unsquashfs_xattr.c
sed -i.bak '/#include <sys\/xattr.h>/a\
\
#ifdef __APPLE__\
// macOS uses setxattr/getxattr instead of lsetxattr/lgetxattr\
#define lsetxattr(path, name, value, size, flags) setxattr(path, name, value, size, 0, flags)\
#define lgetxattr(path, name, value, size) getxattr(path, name, value, size, 0, 0)\
#define llistxattr(path, list, size) listxattr(path, list, size, XATTR_NOFOLLOW)\
#define lremovexattr(path, name) removexattr(path, name, XATTR_NOFOLLOW)\
#endif\
' unsquashfs_xattr.c

# Fix Makefile
sed -i.bak '/-Wall -Werror/a\
\
# Compile LZMA files without -Werror to avoid warnings in third-party code\
LZMA_CFLAGS = $(filter-out -Werror,$(CFLAGS))\
' Makefile

sed -i.bak '/^lzmadaptive:$/a\
\
# Compile LZMA files without -Werror\
$(LZMA_DIR)/C/%.o: $(LZMA_DIR)/C/%.c\
\t$(CC) $(LZMA_CFLAGS) -c -o $@ $<\
' Makefile

sed -i.bak 's|^XZ_SUPPORT = 1|# Temporarily disabled for macOS compatibility\
#XZ_SUPPORT = 1|' Makefile

rm -f *.bak
