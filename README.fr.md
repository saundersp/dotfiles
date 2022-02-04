# @saundersp's dotfiles

*Lisez ceci dans d'autres langues: [English](README.md)*

## Dépendances

### Commun

- alacritty
- neovim
- neofetch
- git
- bash
- Node (with npm)
- Python (with pip)

### Spécifique à Linux

- xorg-xinit
- xorg-xset
- feh
- picom
- i3-gaps
- polybar
- bluez-utils

## Installation

Vous pouvez choisir n'importe quel fichier ou bloc de code, ou simplement utiliser le script auto.sh.

### Utilisation du script d'installation

```bash
# Installation par défaut sur Linux en tant qu'utilisateur (certains fichiers différent s'ils sont installés en tant que root)
./auto.sh
# Pour la version minimale, uniquement en mode terminal
./auto.sh server
# Version Windows
./auto.sh windows
```

### Désinstallation

```bash
./auto.sh remove
# Alternative
./auto.sh uninstall
```

## Scripts d'installation automatique && post-installation

Ces scripts sont destinés à installer/rice une installation minimale de linux à mon goût.

Scripts d'installation automatique (celle-la incluent également une option d'installation minimale):

- Arch
- Artix
- Alpine
- Gentoo
- Void

Scripts post-installation :

- Debian
- Fedora
- OpenSUSE
