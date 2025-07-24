#!/bin/bash

set -e

CHEZMOI_BIN="$HOME/.local/bin/chezmoi"
CHEZMOI_DIR="$HOME/.local/bin"

echo "🚀 Setting up dotfiles with chezmoi..."

# Detect OS and shell
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "debian"
        elif command -v pacman >/dev/null 2>&1; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Check if running in PowerShell
is_powershell() {
    [[ -n "$PSVersionTable" ]] || [[ "$0" == *".ps1" ]]
}

# Install chezmoi
install_chezmoi() {
    echo "📦 Installing chezmoi to $CHEZMOI_DIR..."
    
    # Create .local/bin directory if it doesn't exist
    mkdir -p "$CHEZMOI_DIR"
    
    # Check if chezmoi is already installed
    if [[ -f "$CHEZMOI_BIN" ]] && "$CHEZMOI_BIN" --version >/dev/null 2>&1; then
        echo "✅ chezmoi is already installed at $CHEZMOI_BIN"
        return 0
    fi
    
    # Detect available download tools
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -sfL"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -qO-"
    else
        echo "❌ Error: Neither curl nor wget is available."
        echo "Please install curl or wget and try again:"
        
        OS=$(detect_os)
        case $OS in
            "macos")
                echo "  brew install curl"
                echo "  # or"
                echo "  brew install wget"
                ;;
            "debian")
                echo "  sudo apt-get update && sudo apt-get install -y curl"
                echo "  # or"
                echo "  sudo apt-get update && sudo apt-get install -y wget"
                ;;
            "arch")
                echo "  sudo pacman -S curl"
                echo "  # or"
                echo "  sudo pacman -S wget"
                ;;
            *)
                echo "  Please install curl or wget using your system's package manager"
                ;;
        esac
        exit 1
    fi
    
    # Download and install chezmoi
    echo "📥 Downloading chezmoi using $DOWNLOAD_CMD..."
    if [[ "$DOWNLOAD_CMD" == "curl -sfL" ]]; then
        sh -c "$($DOWNLOAD_CMD https://get.chezmoi.io)" -- -b "$CHEZMOI_DIR"
    else
        sh -c "$($DOWNLOAD_CMD https://get.chezmoi.io)" -- -b "$CHEZMOI_DIR"
    fi
    
    # Verify installation
    if [[ -f "$CHEZMOI_BIN" ]] && "$CHEZMOI_BIN" --version >/dev/null 2>&1; then
        echo "✅ chezmoi installed successfully!"
        echo "📍 Location: $CHEZMOI_BIN"
        echo "🔢 Version: $($CHEZMOI_BIN --version)"
    else
        echo "❌ Failed to install chezmoi"
        exit 1
    fi
}

# Add chezmoi to PATH if not already there
add_to_path() {
    if ! echo "$PATH" | grep -q "$CHEZMOI_DIR"; then
        echo "🛣️  Adding $CHEZMOI_DIR to PATH for this session..."
        export PATH="$CHEZMOI_DIR:$PATH"
        
        # Suggest adding to shell profile
        echo "💡 To permanently add chezmoi to your PATH, add this line to your shell profile:"
        echo "   export PATH=\"$CHEZMOI_DIR:\$PATH\""
    fi
}

# Initialize and apply dotfiles
setup_dotfiles() {
    echo "🏗️  Initializing chezmoi..."
    
    # Get the current repository URL
    if [[ -d ".git" ]]; then
        REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
    else
        echo "❌ Error: This script should be run from a git repository"
        exit 1
    fi
    
    if [[ -z "$REPO_URL" ]]; then
        echo "❌ Error: Could not determine git repository URL"
        exit 1
    fi
    
    echo "📂 Repository: $REPO_URL"
    
    # Initialize chezmoi with the repository
    if [[ -d "$HOME/.local/share/chezmoi" ]]; then
        echo "⚠️  chezmoi source directory already exists. Updating..."
        "$CHEZMOI_BIN" git pull
    else
        echo "🔄 Running: chezmoi init $REPO_URL"
        "$CHEZMOI_BIN" init "$REPO_URL"
    fi
    
    # Show what will be applied
    echo "📋 Preview of changes that will be applied:"
    "$CHEZMOI_BIN" diff
    
    # Ask for confirmation
    read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "✨ Applying dotfiles..."
        "$CHEZMOI_BIN" apply
        echo "🎉 Dotfiles applied successfully!"
    else
        echo "⏸️  Skipping apply. You can run 'chezmoi apply' manually later."
    fi
}

# Main execution
main() {
    echo "🔍 Detected OS: $(detect_os)"
    
    if is_powershell; then
        echo "🐚 PowerShell detected"
        echo "⚠️  Note: This script is optimized for bash/zsh. Consider running in a Unix-like shell."
    fi
    
    install_chezmoi
    add_to_path
    setup_dotfiles
    
    echo ""
    echo "🏁 Setup complete!"
    echo "💡 Useful commands:"
    echo "   chezmoi status    - Show status of managed files"
    echo "   chezmoi diff      - Show differences"
    echo "   chezmoi apply     - Apply changes"
    echo "   chezmoi edit      - Edit a file"
}

# Run main function
main "$@"