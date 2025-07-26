# Dotfiles

hch's dotfiles, managed with [`chezmoi`](https://chezmoi.io)

## Quick Start

- **One-line setup** (installs chezmoi + dotfiles):

  ```sh
  # Using curl (Linux/macOS/WSL/Git Bash)
  curl -fsSL https://raw.githubusercontent.com/jason-hchsieh/dotfiles/main/scripts/setup.sh | bash
  ```

  ```sh
  # Using wget (Linux/macOS/WSL/Git Bash)
  wget -qO- https://raw.githubusercontent.com/jason-hchsieh/dotfiles/main/scripts/setup.sh | bash
  ```

  **Note**: For Windows PowerShell users, use WSL, Git Bash, or wait for `setup.ps1` (coming soon).

- Set up on new machine (if chezmoi is already installed):

  ```sh
  chezmoi init --apply jason-hchsieh
  ```

- Update from repo:

  ```sh
  chezmoi update
  ```

- Apply local changes:

  ```sh
  chezmoi apply
  ```

## Dependencies

- oh-my-zsh
- p10k
- neovim
  - luarocks

## MacOS

## Font

Use the `asset/NFHomebrew.terminal` profile.
For a better user experience, consider installing a Nerd Font. See the [reference guide](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#manual-font-installation) for manual font installation instructions.

## TODO

### Script

- [ ] installation script for dependencies
  - [ ] Darwin
  - [ ] Arch Linux
  - [ ] Ubuntu
  - [ ] Window (powershell)


### Configuration

- [x] fd
- [x] fzf
- [x] neovim
- [x] oh-my-zsh
- [x] p10k
- [x] ripgrep
- [x] tmux
- [x] uv

