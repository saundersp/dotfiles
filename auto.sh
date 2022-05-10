#!/usr/bin/env bash

if [[ -z $1 || $1 == 'help' ]]; then
	echo -e "Auto-installation of my dotfiles script helper
Implemented by @saundersp

Command(s) should be formatted like:
\t$0 install
\tInstall all my dotfiles
\t/!\ Note: When executed as root, the script install and apply the patches in the patches folder

\t$0 uninstall|remove
\tRemove all my dotfiles

\t$0 server
\tInstall the server's version of my dotfiles

\t$0 help
\tWhich display this help message."
	exit 0
fi

export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME

CURRENT_FOLDER=$(pwd)
if [[ $1 == 'uninstall' || $1 == 'remove' ]]; then
	rm -rf $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.gitconfig $HOME/.bash_profile \
		$XDG_CONFIG_HOME/i3/config $HOME/.xinitrc $XDG_CONFIG_HOME/nvim/coc-settings.json $HOME/.Xresources \
		$XDG_CONFIG_HOME/polybar/launch.sh $XDG_CONFIG_HOME/polybar/config.ini $XDG_CONFIG_HOME/polybar/scripts \
		$XDG_CONFIG_HOME/ranger/rc.conf $XDG_CONFIG_HOME/ranger/plugins $XDG_CONFIG_HOME/tmux/plugins $HOME/.tmux.conf

elif [ $EUID -ne 0 ]; then
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetch --config neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	mkdir -p $XDG_CONFIG_HOME/neofetch $XDG_CONFIG_HOME/nvim/autoload/plugged $XDG_CONFIG_HOME/tmux/plugins $XDG_CONFIG_HOME/ranger/plugins

	FILENAME=$XDG_CONFIG_HOME/nvim/autoload/plug.vim
	test ! -f $FILENAME && curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > $FILENAME

	test ! -d $XDG_CONFIG_HOME/ranger/plugins/ranger_devicons && git clone https://github.com/alexanderjeurissen/ranger_devicons.git $XDG_CONFIG_HOME/ranger/plugins/ranger_devicons
	ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/ranger/rc.conf $XDG_CONFIG_HOME/ranger/rc.conf
	ln -sf $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/.gitconfig $HOME/.gitconfig

	FILENAME=$XDG_CONFIG_HOME/tmux/plugins/tpm
	test ! -d $FILENAME && git clone https://github.com/tmux-plugins/tpm $FILENAME
	ln -sf $CURRENT_FOLDER/.tmux.conf $HOME/.tmux.conf

	if [[ $1 == 'server' ]]; then
		ln -sf $CURRENT_FOLDER/.bash_profile_server $HOME/.bash_profile
	else
		mkdir -p $XDG_CONFIG_HOME/i3 $XDG_CONFIG_HOME/i3blocks $XDG_CONFIG_HOME/polybar

		ln -sf $CURRENT_FOLDER/polybar/launch.sh $XDG_CONFIG_HOME/polybar/launch.sh
		ln -sf $CURRENT_FOLDER/polybar/config.ini $XDG_CONFIG_HOME/polybar/config.ini
		test ! -d $XDG_CONFIG_HOME/polybar/scripts && ln -sf $CURRENT_FOLDER/polybar/scripts $XDG_CONFIG_HOME/polybar/scripts
		ln -sf $CURRENT_FOLDER/i3/config $XDG_CONFIG_HOME/i3/config
		ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -sf $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -sf $CURRENT_FOLDER/.xinitrc $HOME/.xinitrc
		ln -sf $CURRENT_FOLDER/.bash_profile $HOME/.bash_profile
		ln -sf $CURRENT_FOLDER/.Xresources $HOME/.Xresources
	fi
else
	mkdir -p $XDG_CONFIG_HOME/neofetch

	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/root.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/root.bash_profile $HOME/.bash_profile

	if [[ $1 != 'server' ]]; then
		ln -sf $CURRENT_FOLDER/.Xresources $HOME/.Xresources

		PACKAGES='dmenu st'
		for package in $PACKAGES; do
			if [ ! -d /usr/local/src/$package ]; then
				git clone git://git.suckless.org/$package /usr/local/src/$package
				cd patches
				./$package.sh
				cd ..
			fi
		done
	fi
fi
