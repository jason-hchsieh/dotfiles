#!/usr/bin/env bash

set -e

# Detect OS
OS="$(uname | tr '[:upper:]' '[:lower:]')"
echo "Detected OS: $OS"

install_neovim() {
    if ! command -v nvim &>/dev/null; then
        echo "Installing Neovim..."
        if [[ "$OS" == "darwin" ]]; then
            brew install neovim
        elif [[ -f /etc/arch-release ]]; then
            sudo pacman -Syu --noconfirm neovim
        elif [[ -f /etc/debian_version ]]; then
            sudo apt update
            sudo apt install -y neovim
        else
            echo "Unsupported Linux distribution"
        fi
    else
        echo "Neovim already installed."
    fi
}

install_zsh_ohmyzsh() {
    if ! command -v zsh &>/dev/null; then
        echo "Installing Zsh..."
        if [[ "$OS" == "darwin" ]]; then
            brew install zsh
        elif [[ -f /etc/arch-release ]]; then
            sudo pacman -Syu --noconfirm zsh
        elif [[ -f /etc/debian_version ]]; then
            sudo apt update
            sudo apt install -y zsh
        fi
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh already installed."
    fi

    # Change shell if not already zsh
    CURRENT_SHELL="$(basename "$SHELL")"
    ZSH_PATH="$(command -v zsh)"
    if [[ "$CURRENT_SHELL" != "zsh" ]]; then
        echo "Changing default shell to zsh..."
        chsh -s "$ZSH_PATH"
        echo "Shell changed. You may need to log out and back in for it to take effect."
    else
        echo "zsh is already the default shell."
    fi
}

install_p10k() {
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        echo "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    else
        echo "powerlevel10k already installed."
    fi
}

main() {
    install_neovim
    install_zsh_ohmyzsh
    install_p10k
    echo "Setup complete."
}

main

