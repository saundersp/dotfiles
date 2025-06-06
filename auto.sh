#!/bin/sh

if [ -z "$1" ] || [ "$1" = 'help' ] || [ "$1" = 'h' ] || [ "$1" = '--help' ]; then
	echo "Auto-installation of my dotfiles script helper
Implemented by @saundersp

USAGE $0 FLAG
Available flags:
	-i, i, install, --install	Install all my dotfiles /!\ Note: When executed as root, the script install and apply the patches in the patches folder
	-r, r, remove, --remove		Remove all my dotfiles
	-s, s, server, --server		Install the server's version of my dotfiles
	-h, h, help, --help		Show this help message"
	exit 0
fi

export XDG_CONFIG_HOME="$HOME"/.XDG/config
export XDG_CACHE_HOME="$HOME"/.XDG/cache
export XDG_DATA_HOME="$HOME"/.XDG/data
export XDG_STATE_HOME="$HOME"/.XDG/state
export XDG_RUNTIME_DIR="$HOME"/.XDG/runtime
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"

CURRENT_FOLDER=$(pwd)
if [ "$1" = '-r' ] || [ "$1" = 'r' ] || [ "$1" = 'remove' ] || [ "$1" = '--remove' ]; then
	rm -rf "$XDG_CONFIG_HOME"/nvim/init.lua "$XDG_CONFIG_HOME"/fastfetch/config.jsonc "$HOME"/.bashrc "$XDG_CONFIG_HOME"/git/config \
		"$HOME"/.profile "$XDG_CONFIG_HOME"/i3/config "$HOME"/.xinitrc "$XDG_CONFIG_HOME"/X11/Xresources "$XDG_CONFIG_HOME"/zathura/zathurarc \
		"$XDG_CONFIG_HOME"/polybar/launch.sh "$XDG_CONFIG_HOME"/polybar/config.ini "$XDG_CONFIG_HOME"/polybar/scripts "$XDG_CONFIG_HOME"/starship.toml \
		"$XDG_CONFIG_HOME"/yazi/yazi.toml "$XDG_CONFIG_HOME"/yazi/theme.toml "$XDG_CONFIG_HOME"/yazi/keymap.toml "$XDG_CONFIG_HOME"/tmux/tmux.conf \
		"$XDG_CONFIG_HOME"/espanso/match/base.yml "$XDG_CONFIG_HOME"/espanso/config/default.yml "$XDG_CONFIG_HOME"/rofi/config.rasi

	FILENAME="$XDG_DATA_HOME"/nvim/lazy/lazy.nvim
	test -d "$FILENAME" && rm -rf "$FILENAME"
elif [ "$(id -u)" -ne 0 ]; then
	mkdir -p "$XDG_CONFIG_HOME"/nvim/autoload "$XDG_CONFIG_HOME"/yazi "$XDG_CONFIG_HOME"/tmux "$XDG_CONFIG_HOME"/git \
		"$XDG_CONFIG_HOME"/fastfetch "$XDG_CONFIG_HOME"/espanso/config "$XDG_CONFIG_HOME"/espanso/match "$XDG_CONFIG_HOME"/rofi \
		"$XDG_CONFIG_HOME"/zathura

	ln -sf "$CURRENT_FOLDER"/fastfetch/config.jsonc "$XDG_CONFIG_HOME"/fastfetch/config.jsonc
	ln -sf "$CURRENT_FOLDER"/yazi/yazi.toml "$XDG_CONFIG_HOME"/yazi/yazi.toml
	ln -sf "$CURRENT_FOLDER"/yazi/theme.toml "$XDG_CONFIG_HOME"/yazi/theme.toml
	ln -sf "$CURRENT_FOLDER"/yazi/keymap.toml "$XDG_CONFIG_HOME"/yazi/keymap.toml
	ln -sf "$CURRENT_FOLDER"/bash/bashrc "$HOME"/.bashrc
	ln -sf "$CURRENT_FOLDER"/git/config "$XDG_CONFIG_HOME"/git/config
	ln -sf "$CURRENT_FOLDER"/tmux/tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
	ln -sf "$CURRENT_FOLDER"/starship.toml "$XDG_CONFIG_HOME"/starship.toml

	if [ "$1" = '-s' ] || [ "$1" = 's' ] || [ "$1" = 'server' ] || [ "$1" = '--server' ]; then
		ln -sf "$CURRENT_FOLDER"/shell_profile/profile_server "$HOME"/.profile
		ln -sf "$CURRENT_FOLDER"/nvim/server_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
	else
		mkdir -p "$XDG_CONFIG_HOME"/i3 "$XDG_CONFIG_HOME"/polybar "$XDG_CONFIG_HOME"/X11

		ln -sf "$CURRENT_FOLDER"/nvim/init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
		ln -sf "$CURRENT_FOLDER"/nvim/spell "$XDG_CONFIG_HOME"/nvim/spell
		ln -sf "$CURRENT_FOLDER"/polybar/launch.sh "$XDG_CONFIG_HOME"/polybar/launch.sh
		ln -sf "$CURRENT_FOLDER"/polybar/config.ini "$XDG_CONFIG_HOME"/polybar/config.ini
		test ! -d "$XDG_CONFIG_HOME"/polybar/scripts && ln -sf "$CURRENT_FOLDER"/polybar/scripts "$XDG_CONFIG_HOME"/polybar/scripts
		ln -sf "$CURRENT_FOLDER"/i3/config "$XDG_CONFIG_HOME"/i3/config
		ln -sf "$CURRENT_FOLDER"/picom "$XDG_CONFIG_HOME"
		ln -sf "$CURRENT_FOLDER"/shell_profile/profile "$HOME"/.profile
		ln -sf "$CURRENT_FOLDER"/X11/xinitrc "$HOME"/.xinitrc
		ln -sf "$CURRENT_FOLDER"/X11/Xresources "$XDG_CONFIG_HOME"/X11/Xresources
		ln -sf "$CURRENT_FOLDER"/espanso/config/default.yml "$XDG_CONFIG_HOME"/espanso/config/default.yml
		ln -sf "$CURRENT_FOLDER"/espanso/match/base.yml "$XDG_CONFIG_HOME"/espanso/match/base.yml
		ln -sf "$CURRENT_FOLDER"/rofi/config.rasi "$XDG_CONFIG_HOME"/rofi/config.rasi
		ln -sf "$CURRENT_FOLDER"/zathura/zathurarc "$XDG_CONFIG_HOME"/zathura/zathurarc
	fi

	if command -v nvim >> /dev/null; then
		nvim --headless -c 'lua if vim.fn.exists(":Lazy") ~= 0 then vim.cmd("Lazy! sync") end' +qa
		nvim --headless -c 'lua if vim.fn.exists(":MasonUpdate") ~= 0 then vim.cmd("MasonUpdate") end' +q
		nvim --headless -c 'lua if vim.fn.exists(":MasonUpdateAll") ~= 0 then vim.cmd("MasonUpdateAll") else os.exit(0) end' -c 'autocmd User MasonUpdateAllComplete quitall'
		nvim --headless -c 'lua if vim.fn.exists(":TSUpdateSync") ~= 0 then vim.cmd("TSUpdateSync") end' +q
	fi
else
	mkdir -p "$XDG_CONFIG_HOME"/tmux "$XDG_CONFIG_HOME"/nvim "$XDG_CONFIG_HOME"/fastfetch

	ln -sf "$CURRENT_FOLDER"/fastfetch/config.jsonc "$XDG_CONFIG_HOME"/fastfetch/config.jsonc
	ln -sf "$CURRENT_FOLDER"/bash/root.bashrc "$HOME"/.bashrc
	ln -sf "$CURRENT_FOLDER"/shell_profile/root.profile "$HOME"/.profile
	ln -sf "$CURRENT_FOLDER"/tmux/root.tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
	ln -sf "$CURRENT_FOLDER"/nvim/root_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
	ln -sf "$CURRENT_FOLDER"/updater.sh "$HOME"/updater.sh

	if [ "$1" != '-s' ] && [ "$1" != 's' ] && [ "$1" != 'server' ] && [ "$1" != '--server' ]; then
		git clone git://git.suckless.org/st /usr/local/src/st
		(cd patches && ./patch.sh st)
	fi
fi
