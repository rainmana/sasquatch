#!/bin/bash
# Script to download squashfs-tools v4.3, apply the patches, perform a clean build, and install.

# If not root, perform 'make install' with sudo
if [ $UID -eq 0 ]
then
    SUDO=""
else
    SUDO="sudo"
fi

# Detect OS and install prerequisites
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! hash brew &>/dev/null; then
        echo "Error: Homebrew is required for macOS. Please install it from https://brew.sh"
        exit 1
    fi
    echo "Installing prerequisites via Homebrew..."
    # Check and install only missing packages to avoid unnecessary upgrades
    for pkg in xz lzo zlib; do
        if ! brew list "$pkg" &>/dev/null; then
            echo "Installing $pkg..."
            brew install "$pkg"
        else
            echo "$pkg is already installed, skipping..."
        fi
    done
    
    # Detect Homebrew prefix (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
    if [ -d "/opt/homebrew" ]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
    
    export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
    # Note: LDFLAGS and CPPFLAGS are set later, just before the make command, to avoid duplication
elif hash apt-get &>/dev/null; then
    # Debian/Ubuntu
    $SUDO apt-get install build-essential liblzma-dev liblzo2-dev zlib1g-dev
fi

# Make sure we're working in the same directory as the build.sh script
# macOS-compatible way to get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Download squashfs4.3.tar.gz if it does not already exist
if [ ! -e squashfs4.3.tar.gz ]
then
    if hash wget &>/dev/null; then
        wget https://downloads.sourceforge.net/project/squashfs/squashfs/squashfs4.3/squashfs4.3.tar.gz
    elif hash curl &>/dev/null; then
        curl -L -o squashfs4.3.tar.gz https://downloads.sourceforge.net/project/squashfs/squashfs/squashfs4.3/squashfs4.3.tar.gz
    else
        echo "Error: Neither wget nor curl is available. Please install one of them."
        exit 1
    fi
fi

# Remove any previous squashfs4.3 directory to ensure a clean patch/build
rm -rf squashfs4.3

# Extract squashfs4.3.tar.gz
tar -zxvf squashfs4.3.tar.gz

# Patch, build, and install the source
cd squashfs4.3
patch -p0 < ../patches/patch0.txt

# Apply macOS compatibility fixes if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    python3 ../patches/fix-macos.py squashfs-tools
fi

cd squashfs-tools

# Set library paths for macOS if needed
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Detect Homebrew prefix (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
    if [ -d "/opt/homebrew" ]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
    # Set LDFLAGS and CPPFLAGS - these will be used by make
    LDFLAGS_VALUE="-L$HOMEBREW_PREFIX/lib"
    CPPFLAGS_VALUE="-I$HOMEBREW_PREFIX/include"
    export LDFLAGS="$LDFLAGS_VALUE $LDFLAGS"
    export CPPFLAGS="$CPPFLAGS_VALUE $CPPFLAGS"
    # Pass LDFLAGS and CPPFLAGS explicitly to make (including for make install)
    # This ensures they're available even when make install calls make again
    make LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS" EXTRA_LDFLAGS="$LDFLAGS_VALUE" && $SUDO make install LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS" EXTRA_LDFLAGS="$LDFLAGS_VALUE"
else
    make && $SUDO make install
fi
