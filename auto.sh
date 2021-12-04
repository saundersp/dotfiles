#!/bin/bash

export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME

CURRENT_FOLDER=$(pwd)
if [[ $1 == "uninstall" || $1 == "remove" ]]; then
	rm -rf $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.gitconfig $HOME/.bash_profile \
		$XDG_CONFIG_HOME/alacritty/alacritty.yml $XDG_CONFIG_HOME/i3/config $HOME/.xinitrc $XDG_CONFIG_HOME/nvim/coc-settings.json \
		$XDG_CONFIG_HOME/polybar/launch.sh $XDG_CONFIG_HOME/polybar/config $XDG_CONFIG_HOME/polybar/scripts
elif [ $EUID -ne 0 ]; then
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetch --config neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	mkdir -p $XDG_CONFIG_HOME/neofetch $XDG_CONFIG_HOME/nvim/autoload/plugged

	FILENAME=$XDG_CONFIG_HOME/nvim/autoload/plug.vim
	test ! -f $FILENAME && curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > $FILENAME

	rm -f $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.gitconfig $HOME/.bash_profile

	ln -s $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
	ln -s $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -s $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -s $CURRENT_FOLDER/.gitconfig $HOME/.gitconfig

	if [[ $1 == "server" ]]; then
		ln -s $CURRENT_FOLDER/.bash_profile_server $HOME/.bash_profile
	elif [[ $1 == "windows" ]]; then
		rm -f $XDG_CONFIG_HOME/alacritty/alacritty.yml $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.gitconfig \
			$XDG_CONFIG_HOME/nvim/coc-settings.json

		mkdir -p $XDG_CONFIG_HOME/alacritty

		ln -s $CURRENT_FOLDER/alacritty/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
		ln -s $CURRENT_FOLDER/.bash_profile $HOME/.bash_profile
		ln -s $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -s $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -s $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
		ln -s $CURRENT_FOLDER/.bashrc $HOME/.bashrc
		ln -s $CURRENT_FOLDER/.gitconfig $HOME/.gitconfig
	else
		rm -rf $XDG_CONFIG_HOME/alacritty/alacritty.yml $XDG_CONFIG_HOME/i3/config $HOME/.xinitrc $XDG_CONFIG_HOME/nvim/init.lua \
			$XDG_CONFIG_HOME/polybar/launch.sh $XDG_CONFIG_HOME/polybar/config $XDG_CONFIG_HOME/polybar/scripts $XDG_CONFIG_HOME/nvim/coc-settings.json

		mkdir -p $XDG_CONFIG_HOME/alacritty $XDG_CONFIG_HOME/i3 $XDG_CONFIG_HOME/i3blocks $XDG_CONFIG_HOME/polybar

		FILENAME=$CURRENT_FOLDER/polybar/scripts/system-bluetooth-bluetoothctl.sh
		if [[ $(command -v bluetoothctl >> /dev/null) && ! -f $FILENAME ]]; then
			curl https://raw.githubusercontent.com/polybar/polybar-scripts/master/polybar-scripts/system-bluetooth-bluetoothctl/system-bluetooth-bluetoothctl.sh > $FILENAME
			chmod +x $FILENAME
			sed -i 's/#1//g' $FILENAME
			sed -i 's/#2//g' $FILENAME
			sed -i 's/"$(systemctl is-active "bluetooth.service")" = "active"/bluetoothctl show | grep -q "Powered: yes"/g' $FILENAME
		fi

		ln -s $CURRENT_FOLDER/alacritty/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
		ln -s $CURRENT_FOLDER/polybar/launch.sh $XDG_CONFIG_HOME/polybar/launch.sh
		ln -s $CURRENT_FOLDER/polybar/config $XDG_CONFIG_HOME/polybar/config
		ln -s $CURRENT_FOLDER/polybar/scripts $XDG_CONFIG_HOME/polybar/scripts
		ln -s $CURRENT_FOLDER/i3/config $XDG_CONFIG_HOME/i3/config
		ln -s $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -s $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -s $CURRENT_FOLDER/.xinitrc $HOME/.xinitrc
		ln -s $CURRENT_FOLDER/.bash_profile $HOME/.bash_profile
	fi
else
	mkdir -p $HOME/.XDG/cache $XDG_CONFIG_HOME/neofetch
	rm -r $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.bash_profile

	ln -s $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -s $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -s $CURRENT_FOLDER/root_bash_profile $HOME/.bash_profile
fi
