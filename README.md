# @saundersp's dotfiles

_Read this in other languages: [Français](README.fr.md)_

## Dependencies

- neovim
- neofetch
- git
- bash
- Node (with npm)
- Python (with pip)
- xorg-xinit
- xorg-xset
- feh
- picom
- i3-gaps
- polybar
- tmux
- ranger
- bluez-utils (optionnal)

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
