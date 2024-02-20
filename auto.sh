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
	rm -rf "$XDG_CONFIG_HOME"/nvim/init.lua "$XDG_CONFIG_HOME"/fastfetch "$HOME"/.bashrc "$XDG_CONFIG_HOME"/git/config "$HOME"/.profile \
		"$XDG_CONFIG_HOME"/i3/config "$HOME"/.xinitrc "$XDG_CONFIG_HOME"/nvim/coc-settings.json "$XDG_CONFIG_HOME"/X11/Xresources \
		"$XDG_CONFIG_HOME"/polybar/launch.sh "$XDG_CONFIG_HOME"/polybar/config.ini "$XDG_CONFIG_HOME"/polybar/scripts \
		"$XDG_CONFIG_HOME"/ranger/rc.conf "$XDG_CONFIG_HOME"/ranger/plugins "$XDG_CONFIG_HOME"/tmux/tmux.conf

	FILENAME="$XDG_DATA_HOME"/nvim/lazy/lazy.nvim
	test -d "$FILENAME" && rm -rf "$FILENAME"
	FILENAME="$XDG_CONFIG_HOME"/ranger/plugins/ranger_devicons
	test -d "$FILENAME" && rm -rf "$FILENAME"
elif [ "$(id -u)" -ne 0 ]; then
	mkdir -p "$XDG_CONFIG_HOME"/nvim/autoload "$XDG_CONFIG_HOME"/ranger/plugins "$XDG_CONFIG_HOME"/tmux "$XDG_CONFIG_HOME"/git "$XDG_CONFIG_HOME"/fastfetch

	FILENAME="$XDG_DATA_HOME"/nvim/lazy/lazy.nvim
	test ! -d "$FILENAME" && git clone --filter blob:none https://github.com/folke/lazy.nvim.git --branch stable "$FILENAME"
	FILENAME="$XDG_CONFIG_HOME"/ranger/plugins/ranger_devicons
	test ! -d "$FILENAME" && git clone https://github.com/alexanderjeurissen/ranger_devicons.git "$FILENAME"

	ln -sf "$CURRENT_FOLDER"/nvim/init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
	ln -sf "$CURRENT_FOLDER"/nvim/coc-settings.json "$XDG_CONFIG_HOME"/nvim/coc-settings.json
	ln -sf "$CURRENT_FOLDER"/fastfetch/config.conf "$XDG_CONFIG_HOME"/fastfetch/config.conf
	ln -sf "$CURRENT_FOLDER"/ranger/rc.conf "$XDG_CONFIG_HOME"/ranger/rc.conf
	ln -sf "$CURRENT_FOLDER"/.bashrc "$HOME"/.bashrc
	ln -sf "$CURRENT_FOLDER"/.gitconfig "$XDG_CONFIG_HOME"/git/config
	ln -sf "$CURRENT_FOLDER"/.tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf

	if [ "$1" = '-s' ] || [ "$1" = 's' ] || [ "$1" = 'server' ] || [ "$1" = '--server' ]; then
		ln -sf "$CURRENT_FOLDER"/.profile_server "$HOME"/.profile
	else
		mkdir -p "$XDG_CONFIG_HOME"/i3 "$XDG_CONFIG_HOME"/polybar "$XDG_CONFIG_HOME"/X11

		ln -sf "$CURRENT_FOLDER"/polybar/launch.sh "$XDG_CONFIG_HOME"/polybar/launch.sh
		ln -sf "$CURRENT_FOLDER"/polybar/config.ini "$XDG_CONFIG_HOME"/polybar/config.ini
		test ! -d "$XDG_CONFIG_HOME"/polybar/scripts && ln -sf "$CURRENT_FOLDER"/polybar/scripts "$XDG_CONFIG_HOME"/polybar/scripts
		ln -sf "$CURRENT_FOLDER"/i3/config "$XDG_CONFIG_HOME"/i3/config
		ln -sf "$CURRENT_FOLDER"/picom "$XDG_CONFIG_HOME"
		ln -sf "$CURRENT_FOLDER"/.xinitrc "$HOME"/.xinitrc
		ln -sf "$CURRENT_FOLDER"/.profile "$HOME"/.profile
		ln -sf "$CURRENT_FOLDER"/.Xresources "$XDG_CONFIG_HOME"/X11/Xresources
	fi
	nvim --headless -c 'Lazy sync' +q
	nvim --headless -c CocUpdateSync +q
	nvim --headless -c TSUpdateSync +q
else
	mkdir -p "$XDG_CONFIG_HOME"/tmux "$XDG_CONFIG_HOME"/nvim "$XDG_CONFIG_HOME"/fastfetch

	ln -sf "$CURRENT_FOLDER"/fastfetch/config "$XDG_CONFIG_HOME"/fastfetch/config.conf
	ln -sf "$CURRENT_FOLDER"/root.bashrc "$HOME"/.bashrc
	ln -sf "$CURRENT_FOLDER"/root.profile "$HOME"/.profile
	ln -sf "$CURRENT_FOLDER"/root.tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
	ln -sf "$CURRENT_FOLDER"/nvim/root_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
	ln -sf "$CURRENT_FOLDER"/updater.sh "$HOME"/updater.sh

	if [ "$1" != '-s' ] && [ "$1" != 's' ] && [ "$1" != 'server' ] && [ "$1" != '--server' ]; then
		PACKAGES='dmenu st'
		for package in $PACKAGES; do
			if [ ! -d /usr/local/src/"$package" ]; then
				git clone git://git.suckless.org/"$package" /usr/local/src/"$package"
				(cd patches && ./patch.sh "$package")
			fi
		done
	fi
fi

exit 0
