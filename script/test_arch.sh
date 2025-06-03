#!/bin/bash

podman run -it -e TERM=xterm-256color --platform linux/amd64 --rm archlinux bash -c '
  pacman -Syu --noconfirm &&
  pacman -S --noconfirm curl git zsh neovim lua51 luarocks &&
  sh -c "$(curl -fsLS get.chezmoi.io)" &&
  chezmoi init --force --apply jason-hchsieh &&
  exec zsh
'

