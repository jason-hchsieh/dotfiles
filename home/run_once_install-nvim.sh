#!/bin/bash

# Install latest neovim from GitHub releases to ~/.local/bin

INSTALL_DIR="$HOME/.local/bin"
NVIM_PATH="$INSTALL_DIR/nvim"

# Check if already installed in ~/.local/bin
if [ -x "$NVIM_PATH" ]; then
    echo "nvim is already installed at $NVIM_PATH"
    exit 0
fi

# Check if installed elsewhere
if command -v nvim &>/dev/null; then
    echo "nvim is already installed at $(which nvim)"
    exit 0
fi

echo "Installing latest nvim from GitHub releases..."

# Create install directory
mkdir -p "$INSTALL_DIR"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  NVIM_ARCH="x86_64" ;;
    aarch64) NVIM_ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download latest release
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.appimage"

echo "Downloading from $NVIM_URL..."
if ! curl -fsSL "$NVIM_URL" -o "$NVIM_PATH"; then
    echo "Error: Failed to download nvim"
    exit 1
fi

# Make executable
chmod +x "$NVIM_PATH"

# Verify installation - if FUSE not available, extract the appimage
if "$NVIM_PATH" --version &>/dev/null; then
    echo "nvim installed successfully to $NVIM_PATH"
    "$NVIM_PATH" --version | head -1
else
    echo "AppImage won't run directly (FUSE not available). Extracting..."
    cd "$INSTALL_DIR"
    ./nvim --appimage-extract >/dev/null 2>&1
    rm -f ./nvim
    ln -sf squashfs-root/usr/bin/nvim nvim

    if "$NVIM_PATH" --version &>/dev/null; then
        echo "nvim installed successfully to $NVIM_PATH"
        "$NVIM_PATH" --version | head -1
    else
        echo "Error: Failed to install nvim"
        exit 1
    fi
fi

# Reminder about PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "Note: Make sure $INSTALL_DIR is in your PATH"
fi
