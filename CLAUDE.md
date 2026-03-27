# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/). The source directory uses `.chezmoiroot` set to `home/`, so all managed files live under `home/` and map to `~/`.

## Common Commands

- `chezmoi apply` - Apply dotfiles to home directory
- `chezmoi diff` - Preview changes before applying
- `chezmoi add <file>` - Add a new file to be managed
- `chezmoi execute-template < file.tmpl` - Test template rendering locally

### Testing

- `tests/run.sh` - Run fast tests (template validation)
- `tests/run.sh --e2e` - Run e2e tests only (requires Docker)
- `tests/run.sh --all` - Run all test tiers

## Architecture

### Chezmoi Naming Conventions

Files in `home/` use chezmoi's naming scheme to control behavior:
- `dot_` prefix → hidden file (e.g., `dot_zshrc.tmpl` → `~/.zshrc`)
- `.tmpl` suffix → Go text/template, rendered with chezmoi data
- `exact_` prefix → directory contents are exactly synchronized (extra files removed)
- `private_` prefix → file permissions set to 0600
- `run_once_` prefix → script runs once per machine (tracked by content hash)

### Run-once Scripts

- `run_once_change-shell-to-zsh.sh` - Install and set zsh as default shell
- `run_once_install-nvim.sh` - Install Neovim

### Template Data Model

Defined in `home/.chezmoi.toml.tmpl`. Interactive prompts populate these during `chezmoi init`:
- `.username`, `.email` - User identity (used in git config, etc.)
- `.work` / `.personal` - Machine type toggle
- `.ephemeral` - Whether machine is temporary
- `.sudoer` - Whether user has sudo access
- `.osid` - OS identifier (e.g., `darwin`, `linux-ubuntu`, `linux-arch`)
- `.zshPlugins` - List of oh-my-zsh plugins, also used by `.chezmoiignore.tmpl` to selectively include plugin directories

### External Dependencies

Managed via `home/.chezmoiexternal.toml.tmpl` (auto-downloaded by chezmoi):
- oh-my-zsh (from GitHub archive)
- zsh-syntax-highlighting plugin
- powerlevel10k theme (pinned to latest GitHub release)

### Cross-Platform Support

Templates use `lookPath` to conditionally include config for tools that may not be installed (bat, fdfind, rg, zoxide, tea). The `run_once_change-shell-to-zsh.sh` script handles zsh installation across apt, dnf, yum, pacman, and brew, with a non-sudo fallback path.

### SSH Config

`home/private_dot_ssh/config.tmpl` routes GitHub SSH through port 443 and conditionally adds an HTTP proxy via the `https_proxy` environment variable.

## Conventions

- Templates end with a `vim: set filetype=...` modeline comment for editor syntax highlighting
- Git aliases live in `home/dot_config/git/config.tmpl`, shell aliases in `home/exact_dot_oh-my-zsh/exact_custom/aliases.zsh`
- The repo targets macOS, Arch Linux, Debian-based Linux, and Windows (WSL/Git Bash)
