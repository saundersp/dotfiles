# @saundersp's dotfiles

*Read this in other languages: [Français](README.fr.md)*

## Dependencies

### Common

- alacritty
- neovim
- neofetch
- git
- bash
- Node (with npm)
- Python (with pip)

### Linux specific

- xorg-xinit
- xorg-xset
- feh
- picom
- i3-gaps
- polybar
- bluez-utils

## Installation

Either pick any wanted files, code blocks, or just use the auto.sh script.

### Install helper usage

```bash
# Default Linux as user (some dotfiles differ if installed as root)
./auto.sh
# For the minimal, terminal only, dotfiles
./auto.sh server
# Version Windows
./auto.sh windows
```

### Uninstallation

```bash
./auto.sh remove
# Alternative
./auto.sh uninstall
```

## Installers && post-installers

These scripts are meant to install/rice a minimal Linux installation to my liking.

Installers (these also include a minimal installation option):

- Arch
- Artix
- Alpine
- Gentoo
- Void

Post-installers :

- Debian
- Fedora
- OpenSUSE
