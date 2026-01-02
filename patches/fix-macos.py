#!/usr/bin/env python3
"""Apply macOS compatibility fixes to squashfs-tools source files."""

import os
import re
import sys

def fix_unsquashfs_c(filepath):
    """Fix unsquashfs.c for macOS compatibility."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix sysinfo.h includes
    content = re.sub(
        r'#include <sys/sysinfo.h>\n#include <sys/types.h>\n#include <sys/sysmacros.h>',
        '#ifdef __linux__\n#include <sys/sysinfo.h>\n#include <sys/sysmacros.h>\n#else\n#include <sys/sysctl.h>\n#endif\n#include <sys/types.h>',
        content
    )
    
    # Fix FNM_EXTMATCH - replace in the fnmatch call
    # The original: name, FNM_PATHNAME|FNM_PERIOD|FNM_EXTMATCH) ==
    # Replace with conditional compilation
    pattern = r'name, FNM_PATHNAME\|FNM_PERIOD\|FNM_EXTMATCH\) =='
    replacement = '''name, FNM_PATHNAME|FNM_PERIOD
#ifdef FNM_EXTMATCH
				|FNM_EXTMATCH
#endif
			) =='''
    content = re.sub(pattern, replacement, content)
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Fixed {filepath}")

def fix_unsquashfs_info_c(filepath):
    """Fix unsquashfs_info.c for macOS compatibility."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add POSIX defines at the top
    content = re.sub(
        r'(#include <pthread.h>)',
        '#define _POSIX_C_SOURCE 200809L\n#ifdef __APPLE__\n#define _DARWIN_C_SOURCE\n#endif\n\n\\1',
        content,
        count=1
    )
    
    # Fix timespec
    content = re.sub(
        r'struct timespec timespec = \{ \.tv_sec = 1, \.tv_nsec = 0 \};',
        '#ifndef __APPLE__\nstruct timespec timespec = { .tv_sec = 1, .tv_nsec = 0 };\n#endif',
        content
    )
    
    # Fix signal handling - replace the while loop signal waiting code
    pattern = r'while\(1\) \{(\s+)if\(waiting\)(\s+)sig = sigtimedwait\(&sigmask, NULL, &timespec\);(\s+)else(\s+)sig = sigwaitinfo\(&sigmask, NULL\);'
    replacement = '''while(1) {
#ifdef __APPLE__
		// macOS does not support sigtimedwait/sigwaitinfo, use sigwait instead
		int sig_num;
		if(sigwait(&sigmask, &sig_num) == 0) {
			sig = sig_num;
		} else {
			sig = -1;
		}
#else
		if(waiting)
			sig = sigtimedwait(&sigmask, NULL, &timespec);
		else
			sig = sigwaitinfo(&sigmask, NULL);
#endif'''
    
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Fixed {filepath}")

def fix_unsquashfs_xattr_c(filepath):
    """Fix unsquashfs_xattr.c for macOS compatibility."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add macOS xattr macros
    content = re.sub(
        r'(#include <sys/xattr.h>)',
        '\\1\n\n#ifdef __APPLE__\n// macOS uses setxattr/getxattr instead of lsetxattr/lgetxattr\n#define lsetxattr(path, name, value, size, flags) setxattr(path, name, value, size, 0, flags)\n#define lgetxattr(path, name, value, size) getxattr(path, name, value, size, 0, 0)\n#define llistxattr(path, list, size) listxattr(path, list, size, XATTR_NOFOLLOW)\n#define lremovexattr(path, name) removexattr(path, name, XATTR_NOFOLLOW)\n#endif',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Fixed {filepath}")

def fix_makefile(filepath):
    """Fix Makefile for macOS compatibility."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add LZMA_CFLAGS
    content = re.sub(
        r'(-Wall -Werror)',
        '\\1\n\n# Compile LZMA files without -Werror to avoid warnings in third-party code\nLZMA_CFLAGS = $(filter-out -Werror,$(CFLAGS))',
        content
    )
    
    # Add LZMA compilation rule
    content = re.sub(
        r'(^lzmadaptive:)',
        '\\1\n\n# Compile LZMA files without -Werror\n$(LZMA_DIR)/C/%.o: $(LZMA_DIR)/C/%.c\n\t$(CC) $(LZMA_CFLAGS) -c -o $@ $<',
        content,
        flags=re.MULTILINE
    )
    
    # Disable XZ_SUPPORT
    content = re.sub(
        r'^XZ_SUPPORT = 1',
        '# Temporarily disabled for macOS compatibility\n#XZ_SUPPORT = 1',
        content,
        flags=re.MULTILINE
    )
    
    # Add EXTRA_LDFLAGS for macOS to ensure library paths are always available
    # This ensures make install (which rebuilds) also has the library paths
    if '# macOS: set EXTRA_LDFLAGS for Homebrew libraries' not in content:
        # Add after LZMA_CFLAGS definition
        content = re.sub(
            r'(LZMA_CFLAGS = \$\(filter-out -Werror,\$\(CFLAGS\)\))',
            '\\1\n\n# macOS: set EXTRA_LDFLAGS for Homebrew libraries\nifeq ($(shell uname),Darwin)\n\tifeq ($(wildcard /opt/homebrew/lib),)\n\t\tEXTRA_LDFLAGS ?= -L/usr/local/lib\n\telse\n\t\tEXTRA_LDFLAGS ?= -L/opt/homebrew/lib\n\tendif\nendif',
            content
        )
    
    # Modify install target to not rebuild if binary exists (avoids rebuild without flags)
    # Change install: sasquatch to install: (remove dependency to prevent rebuild)
    content = re.sub(
        r'^install: sasquatch',
        'install:',
        content,
        flags=re.MULTILINE
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Fixed {filepath}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix-macos.py <squashfs-tools-directory>")
        sys.exit(1)
    
    base_dir = sys.argv[1]
    fix_unsquashfs_c(os.path.join(base_dir, 'unsquashfs.c'))
    fix_unsquashfs_info_c(os.path.join(base_dir, 'unsquashfs_info.c'))
    fix_unsquashfs_xattr_c(os.path.join(base_dir, 'unsquashfs_xattr.c'))
    fix_makefile(os.path.join(base_dir, 'Makefile'))
    print("All macOS compatibility fixes applied!")
