#!/bin/sh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set config and data folder for nvim, alacritty etc...
export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
AUR_PATH=$HOME/aur

__setprompt() {
	local LAST_COMMAND=$? # Must come first!

	# Define colours
	local LIGHTGRAY="\033[0;37m"
	local WHITE="\033[1;37m"
	local BLACK="\033[0;30m"
	local DARKGRAY="\033[1;30m"
	local RED="\033[0;31m"
	local LIGHTRED="\033[1;31m"
	local GREEN="\033[0;32m"
	local LIGHTGREEN="\033[1;32m"
	local BROWN="\033[0;33m"
	local YELLOW="\033[1;33m"
	local BLUE="\033[0;34m"
	local LIGHTBLUE="\033[1;34m"
	local MAGENTA="\033[0;35m"
	local LIGHTMAGENTA="\033[1;35m"
	local CYAN="\033[0;36m"
	local LIGHTCYAN="\033[1;36m"
	local NOCOLOR="\033[0m"
	local USER_COLOUR=$DARKGRAY # Normal user
	test $EUID -eq 0 && USER_COLOUR=$LIGHTRED # Root user

	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1="\[${USER_COLOUR}\]┌──(\[${LIGHTRED}\]ERROR\[${USER_COLOUR}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${USER_COLOUR}\])-(\[${RED}\]"
		if [[ $LAST_COMMAND == 1 ]]; then
			PS1+="General error"
		elif [ $LAST_COMMAND == 2 ]; then
			PS1+="Missing keyword, command, or permission problem"
		elif [ $LAST_COMMAND == 126 ]; then
			PS1+="Permission problem or command is not an executable"
		elif [ $LAST_COMMAND == 127 ]; then
			PS1+="Command not found"
		elif [ $LAST_COMMAND == 128 ]; then
			PS1+="Invalid argument to exit"
		elif [ $LAST_COMMAND == 129 ]; then
			PS1+="Fatal error signal 1"
		elif [ $LAST_COMMAND == 130 ]; then
			PS1+="Script terminated by Control-C"
		elif [ $LAST_COMMAND == 131 ]; then
			PS1+="Fatal error signal 3"
		elif [ $LAST_COMMAND == 132 ]; then
			PS1+="Fatal error signal 4"
		elif [ $LAST_COMMAND == 133 ]; then
			PS1+="Fatal error signal 5"
		elif [ $LAST_COMMAND == 134 ]; then
			PS1+="Fatal error signal 6"
		elif [ $LAST_COMMAND == 135 ]; then
			PS1+="Fatal error signal 7"
		elif [ $LAST_COMMAND == 136 ]; then
			PS1+="Fatal error signal 8"
		elif [ $LAST_COMMAND == 137 ]; then
			PS1+="Fatal error signal 9"
		elif [ $LAST_COMMAND -gt 255 ]; then
			PS1+="Exit status out of range"
		else
			PS1+="Unknown error code"
		fi
		PS1+="\[${USER_COLOUR}\])\n├──"
	else
		PS1="\[${USER_COLOUR}\]┌──"
	fi

	# Date & time
	PS1+="(\[${DARKGRAY}\]\[${CYAN}\]$(date +%a-'%-d'\ %b-'%-m'\ %y)\[${DARKGRAY}\]:"
	PS1+="${MAGENTA}$(date +'%-I':%M:%S%P)\[${USER_COLOUR}\])-"

	# User and server
	PS1+="(\[${RED}\]\u@\h"

	# Current directory
	PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${USER_COLOUR}\])-"

	# Total size of files in current directory
	PS1+="(\[${GREEN}\]$(ls -lah | grep -m 1 total | sed 's/total //')\[${DARKGRAY}\]:"

	# Number of files
	PS1+="\[${GREEN}\]$(ls -A -1 | wc -l)\[${USER_COLOUR}\])"

	# Git branch
	PS1+="\[${BLUE}\]$(git branch 2>>/dev/null | sed -n 's/\* \(.*\)/ ( \1)/p')"

	# Python virtual environment
	PS1+="\[${YELLOW}\]$(command -v deactivate >> /dev/null && echo ' ( env)')"

	# Skip to the next line
	PS1+="\r\n\[${USER_COLOUR}\]└─>\[${NOCOLOR}\] "

	# PS2 is used to continue a command using the \ character
	PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
}
PROMPT_COMMAND='__setprompt' # Will run function every time a command is entered

HISTCONTROL=ignoreboth	  # Don't put duplicate lines or lines starting with space in the history
HISTSIZE= HISTFILESIZE=   # Infinite history
stty -ixon                # Disable ctrl-s and ctrl-q.
shopt -s histappend		  # Append to the history file, don't overwrite it
shopt -s cdspell dirspell # Minor error corrections on directories/files names
shopt -s checkwinsize	  # Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s expand_aliases   # Enable the alias keyword

# Enable programmable completion features script by GNU (https://github.com/scop/bash-completion)
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		source /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		source /etc/bash_completion
	fi
fi

# Enable autocompletion as superuser
complete -cf sudo

# Allow the local root to make connections to the X server
command -v xhost >> /dev/null && xhost +local:root >> /dev/null 2>&1

# Add verbosity to common commands
alias	cp="cp -iv" \
		mv="mv -iv" \
		rm="rm -v" \
		mkdir="mkdir -pv" \
		df="df -h" \
		free="free -h"

# Coloured GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Colourful man page
export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

alias	ls="ls -hN --color=auto --group-directories-first" \
		grep="grep --color=auto" \
		fgrep="fgrep --color=auto" \
		egrep="egrep --color=auto" \
		diff="diff --color=auto" \
		ip="ip --color=auto" \
		ll="ls -hNClas --color=auto --group-directories-first"

# Print out escape sequences usable for coloured text on tty.
colours() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colours\e[m\n"
	printf "Values 40..47 are \e[43mbackground colours\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colours
	for fgc in {30..37}; do
		# background colours
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

# Simple command to preview csv files
preview_csv(){
	if [[ -z "$1" || "$1" == "help" || "$1" == "--help" ]]; then
		echo "Usage : $FUNCNAME filename.csv"
		return 0
	elif [[ ! -r $1 ]]; then
		echo "Can't read file $1"
		return 1
	fi
	cat "$1" | sed 's/,/ ,/g' | column -t -s, | less -S -n
}

if command -v neofetch >> /dev/null; then
	alias neofetchupdate='neofetch --config $XDG_CONFIG_HOME/neofetch/config.conf > $XDG_CACHE_HOME/.neofetch'
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetchupdate
	echo -e "\n$(cat $XDG_CACHE_HOME/.neofetch)Available commands :"
	echo "- neofetchupdate                   : update the cached neofetch informations"
else
	echo -e "Available commands :"
fi
if command -v python >> /dev/null; then
	# Activate the python virtual environment in the current folder
	activate(){
		if [[ "$1" == "help" || "$1" == "--help" ]]; then
			echo "Use $FUNCNAME to enable the current folder's python virtual environment"
			return 0
		fi
		if [ -f venv/Scripts/activate ]; then source venv/Scripts/activate
		elif [ -f venv/bin/activate ]; then source venv/bin/activate
		else echo "Python virtual environment not detected !"
		fi
	}
	echo "- activate                         : activate the python virtual environment"
fi
echo "- colours                          : show the colours palette of the current terminal"
echo "- preview_csv <file>               : preview a csv file"
if command -v nvim >> /dev/null; then
	command -v nvim >> /dev/null && alias vi="nvim" vim="nvim" vid="nvim -d" vimdiff="nvim -d"
	echo "- vi or vim <file/directory/?>     : shortcut to nvim"
	echo "- vid or vimdiff <file1> <file2>   : shortcut to nvim diff mode"
fi
echo "- ll <directory/?>                 : detailed ls"
if command -v pacman >> /dev/null; then
	alias pacprune='pacman -Qtdq | sudo pacman -Rns -'
	echo "- pacprune                         : Remove unused packages (orphans)"

	alias pacupdate='sudo pacman -Syu'
	echo "- pacupdate                        : Update every packages"

	aur_install() {
		if [[ -z "$1" || "$1" == "help" || "$1" == "--help" ]]; then
			echo "Usage : $FUNCNAME <git-link>"
			return 0
		fi
		local PACKAGE_NAME=$(basename $1 .git)
		echo Package name : $PACKAGE_NAME
		if [ ! -d $AUR_PATH/$PACKAGE_NAME ]; then
			git clone $1 $AUR_PATH/$PACKAGE_NAME
		else
			git -C $1
		fi
		cd $AUR_PATH/$PACKAGE_NAME
		makepkg -sri
		cd -
	}
	echo "- aur_install <git_link>           : Install specified AUR package to AUR_PATH"

	aur_update() {
		local PACKAGE_NAME
		for PACKAGE_NAME in $(ls $AUR_PATH); do
			if [[ $(git -C $AUR_PATH/$PACKAGE_NAME pull) == "Already up to date." ]]; then
				echo Package $PACKAGE_NAME already up to date
			else
				echo Updating $PACKAGE_NAME
				cd $AUR_PATH/$PACKAGE_NAME
				makepkg -sri
				cd -
			fi
		done
	}
	echo "- aur_update                       : Update every AUR packages"

	aur_uninstall() {
		if [[ -z "$1"  || "$1" == "help" || "$1" == "--help" ]]; then
			echo "Usage : $FUNCNAME <aur-package-name"
			return 0
		fi
		if [[ ! -d $AUR_PATH/$1 ]]; then
			echo No such package : $1
			return 1
		fi
		sudo pacman -Rns $1
		rm -r $AUR_PATH/$1
		echo Uninstalled $1 successfully
	}
	echo "- aur_uninstall <aur-package-name> : Uninstall a specified AUR package"

	aur_list() {
		local PACKAGE_NAME PACMAN_INFO
		for PACKAGE_NAME in $(ls $AUR_PATH); do
			PACMAN_INFO=$(pacman -Q | grep $PACKAGE_NAME)
			if [[ ! -z $PACMAN_INFO ]]; then
				echo - [x] $PACMAN_INFO
			else
				echo - [ ] $PACKAGE_NAME
			fi
		done
	}
	echo "- aur_list                         : List of the installed AUR packages"
fi
command -v xclip >> /dev/null && alias xclip='xclip -selection clipboard' && echo "- xclip                            : copy/paste (with -i) from STDOUT to clipboard"
command -v openvpn >> /dev/null && alias vpn='sudo openvpn ~/.ssh/LinodeVPN.ovpn &' && echo "- vpn                              : easily enable a secure VPN connection"
command -v reflector >> /dev/null && alias update_mirrors='sudo reflector -a 48 -c $(curl -s ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist' && echo "- update_mirrors                   : Update pacman's mirrors"
command -v lazygit >> /dev/null && echo "- lazygit                          : fancy CLI git interface"

if command -v xrandr >> /dev/null; then
	alias hdmi_on="xrandr --output HDMI-1-0 --auto --left-of eDP1"
	echo "- hdmi_on                          : turn on the HDMI connection and put it on the left"
	alias hdmi_off="xrandr --output HDMI-1-0 --off"
	echo "- hdmi_off                         : turn off the HDMI connection"
fi

echo -e "\nBash bang shortcuts remainders :"
#echo "- !!                               : last command"
#echo "- !$                               : last item ran"
echo "- !^                               : first item ran"
echo "- !*                               : all items ran"
