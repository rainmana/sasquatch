# sasquatch

**This is a fork of the original [sasquatch](https://github.com/devttys0/sasquatch) project by [devttys0](https://github.com/devttys0), with updates and fixes for modern macOS (including Apple Silicon) support.**

## About

The `sasquatch` project is a set of patches to the standard unsquashfs utility (part of squashfs-tools) that attempts to add support for as many hacked-up vendor-specific SquashFS implementations as possible.

If the vendor has done something simple like just muck a bit with the header fields, `sasquatch` should sort it out.

If the vendor has made changes to the underlying LZMA compression options, or to how these options are stored in the compressed data blocks, `sasquatch` will attempt to automatically resolve such customizations via a brute-force method.

Additional advanced command line options have been added for testing/debugging.

**Note:** This is beta software.

## Original Project

This project is a fork of the original [sasquatch](https://github.com/devttys0/sasquatch) repository by [devttys0](https://github.com/devttys0). The original project hasn't been updated in several years, and this fork provides:

- **macOS compatibility fixes** - Full support for modern macOS, including Apple Silicon (ARM64)
- **Build script improvements** - Automatic dependency detection and installation
- **Cross-platform support** - Works on both Linux and macOS

All changes in this fork are fixes and improvements to make the original project work on modern systems. The core functionality and patches remain unchanged from the original.

## License

This project is based on squashfs-tools, which is licensed under the **GNU General Public License version 2** (GPL-2.0). As a derivative work, this fork maintains the same license terms.

See the `squashfs4.3/COPYING` file for the full GPL-2.0 license text.

## Prerequisites

You need a C/C++ compiler, plus the liblzma, liblzo and zlib development libraries.

### On Linux (Debian/Ubuntu):
```bash
$ sudo apt-get install build-essential liblzma-dev liblzo2-dev zlib1g-dev
```

### On macOS (including Apple Silicon):
```bash
$ brew install xz lzo zlib
```

**Note:** Homebrew is required for macOS. If you don't have it installed, get it from https://brew.sh

## Installation

The included `build.sh` script will download squashfs-tools v4.3, patch the source, then build and install `sasquatch`:

```bash
$ ./build.sh
```

The script automatically detects your operating system and installs the appropriate dependencies.

## What's Changed in This Fork

This fork includes the following improvements over the original:

- **macOS/Apple Silicon Support**: Fixed compilation issues on modern macOS systems
- **Automatic Dependency Management**: Build script automatically installs required dependencies
- **Improved Build Process**: Better error handling and cross-platform compatibility
- **Fixed Linker Issues**: Resolved library path issues on macOS with Homebrew

## Contributing

Contributions are welcome! This fork aims to maintain compatibility with the original project while adding necessary fixes for modern systems. If you find issues or have improvements, please open an issue or submit a pull request.

## Credits

- **Original Project**: [devttys0/sasquatch](https://github.com/devttys0/sasquatch) by [devttys0](https://github.com/devttys0)
- **Base Tool**: squashfs-tools v4.3
- **Fork Maintainer**: This fork adds macOS compatibility and build improvements
