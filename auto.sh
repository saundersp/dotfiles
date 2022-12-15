#!/bin/sh

if [ -z "$1" ] || [ "$1" = 'help' ] || [ "$1" = 'h' ] || [ "$1" = '--help' ]; then
	echo "Auto-installation of my dotfiles script helper
Implemented by @saundersp

Command(s) should be formatted like:
\t$0 i|install
\tInstall all my dotfiles
\t/!\ Note: When executed as root, the script install and apply the patches in the patches folder

\t$0 r|uninstall|remove
\tRemove all my dotfiles

\t$0 s|server
\tInstall the server's version of my dotfiles

\t$0 h|help|--help
\tWhich display this help message."
	exit 0
fi

export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
export XDG_STATE_HOME=$HOME/.XDG/state
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME $XDG_STATE_HOME

CURRENT_FOLDER=$(pwd)
if [ "$1" = 'uninstall' ] || [ "$1" = 'remove' ] || [ "$1" = 'r' ]; then
	rm -rf $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $XDG_CONFIG_HOME/git/config $HOME/.bash_profile \
		$XDG_CONFIG_HOME/i3/config $HOME/.xinitrc $XDG_CONFIG_HOME/nvim/coc-settings.json $XDG_CONFIG_HOME/X11/Xresources \
		$XDG_CONFIG_HOME/polybar/launch.sh $XDG_CONFIG_HOME/polybar/config.ini $XDG_CONFIG_HOME/polybar/scripts \
		$XDG_CONFIG_HOME/ranger/rc.conf $XDG_CONFIG_HOME/ranger/plugins $XDG_CONFIG_HOME/tmux/tmux.conf

elif [ "$(id -u)" -ne 0 ]; then
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetch --config neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	mkdir -p $XDG_CONFIG_HOME/neofetch $XDG_CONFIG_HOME/nvim/autoload/ $XDG_CONFIG_HOME/ranger/plugins $XDG_CONFIG_HOME/tmux $XDG_CONFIG_HOME/git

	FILENAME=$XDG_DATA_HOME/nvim/site/pack/packer/opt/packer.nvim
	test ! -d $FILENAME && git clone --depth=1 https://github.com/wbthomason/packer.nvim $FILENAME
	FILENAME=$XDG_CONFIG_HOME/ranger/plugins/ranger_devicons
	test ! -d $FILENAME && git clone https://github.com/alexanderjeurissen/ranger_devicons.git $FILENAME
	ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/ranger/rc.conf $XDG_CONFIG_HOME/ranger/rc.conf
	ln -sf $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/.gitconfig $XDG_CONFIG_HOME/git/config
	ln -sf $CURRENT_FOLDER/.tmux.conf $XDG_CONFIG_HOME/tmux/tmux.conf

	if [ "$1" = 'server' ] || [ "$1" = 's' ]; then
		ln -sf $CURRENT_FOLDER/.bash_profile_server $HOME/.bash_profile
	else
		mkdir -p $XDG_CONFIG_HOME/i3 $XDG_CONFIG_HOME/i3blocks $XDG_CONFIG_HOME/polybar $XDG_CONFIG_HOME/X11

		ln -sf $CURRENT_FOLDER/polybar/launch.sh $XDG_CONFIG_HOME/polybar/launch.sh
		ln -sf $CURRENT_FOLDER/polybar/config.ini $XDG_CONFIG_HOME/polybar/config.ini
		test ! -d $XDG_CONFIG_HOME/polybar/scripts && ln -sf $CURRENT_FOLDER/polybar/scripts $XDG_CONFIG_HOME/polybar/scripts
		ln -sf $CURRENT_FOLDER/i3/config $XDG_CONFIG_HOME/i3/config
		ln -sf $CURRENT_FOLDER/picom $XDG_CONFIG_HOME
		ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -sf $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -sf $CURRENT_FOLDER/.xinitrc $HOME/.xinitrc
		ln -sf $CURRENT_FOLDER/.bash_profile $HOME/.bash_profile
		ln -sf $CURRENT_FOLDER/.Xresources $XDG_CONFIG_HOME/X11/Xresources
	fi
	nvim --headless -c 'autocmd User PackerComplete quitall' -c PackerSync
	nvim --headless -c CocUpdateSync +q
else
	mkdir -p $XDG_CONFIG_HOME/neofetch $XDG_CONFIG_HOME/tmux $XDG_CONFIG_HOME/nvim

	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/root.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/root.bash_profile $HOME/.bash_profile
	ln -sf $CURRENT_FOLDER/root.tmux.conf $XDG_CONFIG_HOME/tmux/tmux.conf
	ln -sf $CURRENT_FOLDER/nvim/root_init.lua $XDG_CONFIG_HOME/nvim/init.lua

	if [ "$1" != 'server' ] && [ "$1" != 's' ]; then
		PACKAGES='dmenu st'
		for package in $PACKAGES; do
			if [ ! -d /usr/local/src/$package ]; then
				git clone git://git.suckless.org/$package /usr/local/src/$package
				cd patches
				./patch.sh $package
				cd ..
			fi
		done
	fi
fi
