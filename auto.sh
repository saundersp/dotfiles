#!/usr/bin/env bash

export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME

CURRENT_FOLDER=$(pwd)
if [[ $1 == 'uninstall' || $1 == 'remove' ]]; then
	rm -rf $XDG_CONFIG_HOME/nvim/init.lua $XDG_CONFIG_HOME/neofetch/config.conf $HOME/.bashrc $HOME/.gitconfig $HOME/.bash_profile \
		$XDG_CONFIG_HOME/alacritty/alacritty.yml $XDG_CONFIG_HOME/i3/config $HOME/.xinitrc $XDG_CONFIG_HOME/nvim/coc-settings.json \
		$XDG_CONFIG_HOME/polybar/launch.sh $XDG_CONFIG_HOME/polybar/config $XDG_CONFIG_HOME/polybar/scripts $HOME/.bashrc $HOME/.bash_profile
elif [ $EUID -ne 0 ]; then
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetch --config neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	mkdir -p $XDG_CONFIG_HOME/neofetch $XDG_CONFIG_HOME/nvim/autoload/plugged $XDG_CONFIG_HOME/lf/lfrc

	FILENAME=$XDG_CONFIG_HOME/nvim/autoload/plug.vim
	test ! -f $FILENAME && curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > $FILENAME

	ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/lf/lfrc $XDG_CONFIG_HOME/lf/lfrc
	ln -sf $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/.gitconfig $HOME/.gitconfig

	if [[ $1 == 'server' ]]; then
		ln -sf $CURRENT_FOLDER/.bash_profile_server $HOME/.bash_profile
	elif [[ $1 == 'windows' ]]; then

		mkdir -p $XDG_CONFIG_HOME/alacritty

		ln -sf $CURRENT_FOLDER/alacritty/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
		ln -sf $CURRENT_FOLDER/win.bash_profile $HOME/.bash_profile
		ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -sf $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
		ln -sf $CURRENT_FOLDER/.bashrc $HOME/.bashrc
		ln -sf $CURRENT_FOLDER/.gitconfig $HOME/.gitconfig
	else
		mkdir -p $XDG_CONFIG_HOME/alacritty $XDG_CONFIG_HOME/i3 $XDG_CONFIG_HOME/i3blocks $XDG_CONFIG_HOME/polybar

		FILENAME=$CURRENT_FOLDER/polybar/scripts/system-bluetooth-bluetoothctl.sh
		if [ ! -f $FILENAME ]; then
			if command -v bluetoothctl >> /dev/null; then
				curl https://raw.githubusercontent.com/polybar/polybar-scripts/master/polybar-scripts/system-bluetooth-bluetoothctl/system-bluetooth-bluetoothctl.sh > $FILENAME
				sed -i 's/#1//g' $FILENAME
				sed -i 's/#2//g' $FILENAME
				sed -i 's/"$(systemctl is-active "bluetooth.service")" = "active"/bluetoothctl show | grep -q "Powered: yes"/g' $FILENAME
			else
				touch $FILENAME
			fi
			chmod +x $FILENAME
		fi

		ln -sf $CURRENT_FOLDER/alacritty/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
		ln -sf $CURRENT_FOLDER/polybar/launch.sh $XDG_CONFIG_HOME/polybar/launch.sh
		ln -sf $CURRENT_FOLDER/polybar/config $XDG_CONFIG_HOME/polybar/config
		ln -sf $CURRENT_FOLDER/polybar/scripts $XDG_CONFIG_HOME/polybar/scripts
		ln -sf $CURRENT_FOLDER/i3/config $XDG_CONFIG_HOME/i3/config
		ln -sf $CURRENT_FOLDER/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
		ln -sf $CURRENT_FOLDER/nvim/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json
		ln -sf $CURRENT_FOLDER/.xinitrc $HOME/.xinitrc
		ln -sf $CURRENT_FOLDER/.bash_profile $HOME/.bash_profile
	fi
else
	mkdir -p $HOME/.XDG/cache $XDG_CONFIG_HOME/neofetch

	ln -sf $CURRENT_FOLDER/neofetch/config.conf $XDG_CONFIG_HOME/neofetch/config.conf
	ln -sf $CURRENT_FOLDER/.bashrc $HOME/.bashrc
	ln -sf $CURRENT_FOLDER/root.bash_profile $HOME/.bash_profile
fi
