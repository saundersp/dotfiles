# @saundersp's dotfiles

_Lisez ceci dans d'autres langues : [English](README.md)_

## Paquets utilisés

- neovim : Unique fichier de configuration utilisateur init.lua, ainsi que la configuration root root_init.lua sans plugins
- git : email et nom globaux, autorise certains dossiers sûrs
- bash : dossier shell_profile avec bashrc utilisateur et root.bashrc qui ne diffère que de l'helper AUR et les logiciels de bureau (X11)
- tmux : Configuration utilisateur et root, la configuration root essayera de lire le niveau de batterie et de luminosité, l'utilisateur est plus minimal
- fastfetch : Rendu très similaire à neofetch
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

### Bureau seulement

- i3-gaps :
- polybar :
- picom :
- xorg-xrdb :
- xorg-xinit
- xorg-xset
- xorg-xrandr
- xorg-xclip
- pulseaudio
- feh
- deskflow

## Installation

Vous pouvez choisir n'importe quel fichier ou bloc de code, ou simplement utiliser le script auto.sh.

### Utilisation du script d'installation

```bash
# Installation par défaut sur Linux en tant qu'utilisateur (certains fichiers différent s'ils sont installés en tant que root)
./auto.sh desktop
# Pour la version minimale, uniquement en mode terminal
./auto.sh server
```

### Désinstallation

```bash
./auto.sh uninstall
```

## Scripts d'installation automatique && post-installation

Ces scripts sont destinés à installer et personnaliser une installation Artix ou Gentoo à partir de zéro et à mon goût.

## Configuration de kernel custom

- VIRTUAL.config : Gentoo dans VirtualBox
- LAPTOP.config : Ordinateur portable Gentoo
- STREAMPC.config : PC Encodeur de vidéo
- MAINPC.config : PC multitâches
- MAXIMUM.config : Ordinateur portable Gentoo mais avec tout activé (non recommandé)
