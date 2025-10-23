#!/bin/sh

set -e

export XDG_CONFIG_HOME="$HOME"/.XDG/config
export XDG_CACHE_HOME="$HOME"/.XDG/cache
export XDG_DATA_HOME="$HOME"/.XDG/data
export XDG_STATE_HOME="$HOME"/.XDG/state
export XDG_RUNTIME_DIR="$HOME"/.XDG/runtime

USAGE="\
Script to help the installation of my dotfiles into a custom XDG_CONFIG_HOME: $XDG_CONFIG_HOME

USAGE $0 [FLAG]
Available flags:
	desktop, --desktop		Install the dotfiles related for desktop usage /!\ Note: When executed as root, the script install and apply the patches in the patches folder
	server, --server		Install the dotfiles related for server's usage.
	uninstall, --uninstall		Uninstall all of my dotfiles regardless if desktop or server.
	help, -h, --help		Show this usage message"

cmd_check(){
	command -v "$1" > /dev/null
}

link(){
	ln -sfv "$(pwd)"/"$1" "$2"
}

pkg_link(){
	if [ -z "$3" ]; then
		cmd_check "$1" && link "$1" "$2"
	else
		cmd_check "$1" && link "$2" "$3"
	fi
}

case $1 in
	desktop|--desktop) # Desktop version of the dotfiles
		mkdir -pv \
			"$XDG_CONFIG_HOME" \
			"$XDG_CACHE_HOME" \
			"$XDG_DATA_HOME" \
			"$XDG_STATE_HOME" \
			"$XDG_RUNTIME_DIR"

		# Common configuration files
		pkg_link fastfetch "$XDG_CONFIG_HOME"/fastfetch
		pkg_link starship starship.toml "$XDG_CONFIG_HOME"/starship.toml
		pkg_link yazi "$XDG_CONFIG_HOME"/yazi

		if [ "$(id -u)" -eq 0 ]; then
			# Only root configuration files

			link shell_profile/root.profile "$HOME"/.profile
			link updater.sh "$HOME"/updater.sh

			pkg_link bash bash/root.bashrc "$HOME"/.bashrc

			if cmd_check nvim; then
				mkdir -v "$XDG_CONFIG_HOME"/nvim
				link nvim/root_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
			fi

			if cmd_check tmux; then
				mkdir -v "$XDG_CONFIG_HOME"/tmux
				link tmux/root.tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
			fi

			# Custom patched packages
			git clone git://git.suckless.org/st /usr/local/src/st
			(cd patches && ./patch.sh st)
		else
			# All users configuration files

			link shell_profile/profile "$HOME"/.profile

			pkg_link bash bash/bashrc "$HOME"/.bashrc
			pkg_link espanso "$XDG_CONFIG_HOME"/espanso
			pkg_link git "$XDG_CONFIG_HOME"/git
			pkg_link i3 "$XDG_CONFIG_HOME"/i3
			pkg_link kitty "$XDG_CONFIG_HOME"/kitty
			pkg_link picom "$XDG_CONFIG_HOME"
			pkg_link polybar "$XDG_CONFIG_HOME"/polybar
			pkg_link rofi "$XDG_CONFIG_HOME"/rofi
			pkg_link xrdb X11 "$XDG_CONFIG_HOME"/X11
			pkg_link xinit X11/xinitrc "$HOME"/.xinitrc
			pkg_link zathura "$XDG_CONFIG_HOME"/zathura

			if cmd_check nvim; then
				mkdir -v "$XDG_CONFIG_HOME"/nvim
				link nvim/init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
				link nvim/spell "$XDG_CONFIG_HOME"/nvim/spell
				nvim --headless -c 'lua vim.cmd("Lazy! sync")' +qa
				nvim --headless -c 'lua vim.cmd("MasonUpdate")' +q
				nvim --headless -c 'lua vim.cmd("MasonUpdateAll")' -c 'autocmd User MasonUpdateAllComplete quitall'
				nvim --headless -c 'lua vim.cmd("TSInstallSync! " .. (table.concat(require("nvim-treesitter.configs").get_ensure_installed_parsers(), " ")))' +q
				nvim --headless -c 'lua vim.cmd("TypstPreviewUpdate")' +q
			fi

			if cmd_check tmux; then
				mkdir -v "$XDG_CONFIG_HOME"/tmux
				link tmux/tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
			fi
		fi
	;;
	server|--server) # Server version of the dotfiles
		mkdir -pv \
			"$XDG_CONFIG_HOME" \
			"$XDG_CACHE_HOME" \
			"$XDG_DATA_HOME" \
			"$XDG_STATE_HOME" \
			"$XDG_RUNTIME_DIR"

		# Common configuration files
		pkg_link fastfetch "$XDG_CONFIG_HOME"/fastfetch
		pkg_link starship starship.toml "$XDG_CONFIG_HOME"/starship.toml
		pkg_link yazi "$XDG_CONFIG_HOME"/yazi

		if [ "$(id -u)" -eq 0 ]; then
			# Only root configuration files

			link shell_profile/root.profile "$HOME"/.profile
			link updater.sh "$HOME"/updater.sh

			pkg_link bash bash/root.bashrc "$HOME"/.bashrc

			if cmd_check nvim; then
				mkdir -v "$XDG_CONFIG_HOME"/nvim
				link nvim/root_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
			fi

			if cmd_check tmux; then
				mkdir -v "$XDG_CONFIG_HOME"/tmux
				link tmux/root.tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
			fi
		else
			# All users configuration files

			link shell_profile/profile_server "$HOME"/.profile

			pkg_link bash bash/bashrc "$HOME"/.bashrc
			pkg_link git "$XDG_CONFIG_HOME"/git

			if cmd_check nvim; then
				mkdir -v "$XDG_CONFIG_HOME"/nvim
				link nvim/server_init.lua "$XDG_CONFIG_HOME"/nvim/init.lua
				nvim --headless -c 'lua vim.cmd("Lazy! sync")' +qa
				nvim --headless -c 'lua vim.cmd("TSInstallSync! " .. (table.concat(require("nvim-treesitter.configs").get_ensure_installed_parsers(), " ")))' +q
			fi

			if cmd_check tmux; then
				mkdir -v "$XDG_CONFIG_HOME"/tmux
				link tmux/tmux.conf "$XDG_CONFIG_HOME"/tmux/tmux.conf
			fi
		fi
	;;
	uninstall|--uninstall)
		rm -rf \
			"$HOME"/.bashrc \
			"$XDG_CONFIG_HOME"/espanso \
			"$XDG_CONFIG_HOME"/fastfetch \
			"$XDG_CONFIG_HOME"/git \
			"$XDG_CONFIG_HOME"/i3 \
			"$XDG_CONFIG_HOME"/kitty \
			"$XDG_CONFIG_HOME"/nvim \
			"$XDG_DATA_HOME"/nvim/lazy \
			"$XDG_CONFIG_HOME"/picom \
			"$XDG_CONFIG_HOME"/polybar \
			"$XDG_CONFIG_HOME"/rofi \
			"$HOME"/.profile \
			"$XDG_CONFIG_HOME"/starship.toml \
			"$XDG_CONFIG_HOME"/tmux \
			"$HOME"/updater.sh \
			"$XDG_CONFIG_HOME"/X11 \
			"$HOME"/.xinitrc \
			"$XDG_CONFIG_HOME"/yazi \
			"$XDG_CONFIG_HOME"/zathura
	;;
	-h|help|--help)
		echo "$USAGE"
		exit 0
	;;
	*)
		echo "$USAGE"
		exit 1
	;;
esac
