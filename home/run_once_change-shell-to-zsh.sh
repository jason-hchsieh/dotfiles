#!/bin/bash

# Change default shell to zsh, installing if necessary

# Check if user has sudo access
CAN_SUDO=false
if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
    CAN_SUDO=true
fi

ZSH_PATH=$(which zsh 2>/dev/null)

if [ -z "$ZSH_PATH" ]; then
    if [ "$CAN_SUDO" = true ]; then
        echo "zsh is not installed. Installing..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y zsh
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y zsh
        elif command -v yum &>/dev/null; then
            sudo yum install -y zsh
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm zsh
        elif command -v brew &>/dev/null; then
            brew install zsh
        else
            echo "Could not detect package manager. Please install zsh manually."
            exit 1
        fi
        ZSH_PATH=$(which zsh)
    else
        echo "zsh is not installed. Trying user-space installation..."
        if command -v brew &>/dev/null; then
            brew install zsh
            ZSH_PATH=$(brew --prefix)/bin/zsh
        elif command -v conda &>/dev/null; then
            conda install -y -c conda-forge zsh
            ZSH_PATH=$(dirname "$(which conda)")/zsh
        else
            echo "zsh is not installed and you don't have sudo access."
            echo "Please install Homebrew or Conda, or ask an administrator to install zsh."
            exit 1
        fi
    fi
    ZSH_PATH=$(which zsh 2>/dev/null || echo "$ZSH_PATH")
fi

if [ "$SHELL" = "$ZSH_PATH" ]; then
    echo "Shell is already set to zsh."
    exit 0
fi

echo "Changing default shell to zsh..."
if [ "$CAN_SUDO" = true ]; then
    # Add to /etc/shells if not present
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    sudo chsh -s "$ZSH_PATH" "$USER"
else
    # Try chsh first, fall back to .bashrc if it fails (zsh not in /etc/shells)
    if ! chsh -s "$ZSH_PATH" 2>/dev/null; then
        echo "chsh failed (zsh not in /etc/shells). Adding exec zsh to .bashrc..."
        BASHRC="$HOME/.bashrc"
        if ! grep -q "exec.*zsh" "$BASHRC" 2>/dev/null; then
            echo "" >> "$BASHRC"
            echo "# Switch to zsh" >> "$BASHRC"
            echo "export SHELL=\"$ZSH_PATH\"" >> "$BASHRC"
            echo "exec \"$ZSH_PATH\" -l" >> "$BASHRC"
        fi
        echo "Done. Restart your terminal to use zsh."
    fi
fi
