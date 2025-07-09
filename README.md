# @saundersp's dotfiles

_Read this in other languages: [Français](README.fr.md)_

## Software used

- neovim : User has a single init.lua config, root config has root_init.lua without plugins
- git : Global email and name, allows certain safe directories
- bash : shell_profile directory with user bashrc and root.bashrc only differs by AUR helper and desktop software (X11)
- tmux : User and root config, root config tries to read battery and brightness level, user is more minimal
- fastfetch : Rendering very similar to neofetch
- Node (with npm)
- Python (with pip)
- gcc
- g++
- curl
- unzip
- yazi
- fzf
- bat
- arduino-cli
- Docker
- Docker Compose
- eza
- bluez-utils
- lazygit
- lazydocker
- difftastic

### Desktop only

- i3-gaps : no border, launching a startup layout given a custom profile, resize mode with Mod+r, system mode with Mod+Home to logout, poweroff etc.
- polybar : Monochromatic with a few custom scripts
- picom : VSync, gaussian blur, fading and rounded corners
- xorg-xrdb : Every colour is set in Xresources when possible
- xorg-xinit
- xorg-xset
- xorg-xrandr
- xorg-xclip
- pulseaudio
- feh
- deskflow

## Installation

Either pick any wanted files, code blocks, or just use the auto.sh script.

### Install helper usage

```bash
# Default Linux as user (some dotfiles differ if installed as root)
./auto.sh install
# For the minimal, terminal only, dotfiles
./auto.sh server
```

### Uninstallation

```bash
./auto.sh remove
# Alternative
./auto.sh uninstall
```

## Installers && post-installers

These scripts are meant to install and rice an Artix or Gentoo Linux installation from scratch to my liking.

## Custom kernel configs

- VIRTUAL.config : Gentoo in VirtualBox
- LAPTOP.config : Gentoo laptop
- STREAMPC.config : Gentoo video encoding PC
- MAINPC.config : Gentoo multipurpose PC
- MAXIMUM.config : Gentoo laptop but with everything enabled (not recommended)
