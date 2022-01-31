#!/bin/sh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set config and data folder for nvim, alacritty etc...
export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
AUR_PATH=$HOME/aur

# Define colours
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'
BLACK='\033[0;30m'
DARKGRAY='\033[1;30m'
RED='\033[0;31m'
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
LIGHTGREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
MAGENTA='\033[0;35m'
LIGHTMAGENTA='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
NOCOLOUR='\033[0m'
USER_COLOUR=$DARKGRAY # Normal user
test $EUID -eq 0 && USER_COLOUR=$LIGHTRED # Root user

# Define text styles
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINED='\033[4m'
BLINKING='\033[5m'

__setprompt() {
	local LAST_COMMAND=$? # Must come first!

	PS1="\[${USER_COLOUR}\]┌──"
	# Show error exit code if there is one
	if [[ $LAST_COMMAND != 0 ]]; then
		PS1+="(\[${LIGHTRED}\]ERROR\[${USER_COLOUR}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${USER_COLOUR}\])\n├──"
	fi

	# Time
	PS1+="(\[${DARKGRAY}\]\[${LIGHTBLUE}\]$(date +%I:%M:%S•%p)\[${USER_COLOUR}\])-"

	# User and hostname
	PS1+="(\[${MAGENTA}\]\u@\h"

	# Current directory
	PS1+="\[${DARKGRAY}\])-(\[${BROWN}\]\w\[${USER_COLOUR}\])"

	# Git branch
	PS1+="\[${BLUE}\]$(git branch 2>>/dev/null | sed -n 's/\* \(.*\)/ ( \1)/p')"

	# Python virtual environment
	PS1+="\[${YELLOW}\]$(command -v deactivate >> /dev/null && echo ' ( env)')"

	# Skip to the next line
	PS1+="\r\n\[${USER_COLOUR}\]└─>\[${NOCOLOUR}\] "

	# PS2 is used to continue a command using the \ character
	PS2="\[${DARKGRAY}\]>\[${NOCOLOUR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${DARKGRAY}\]+\[${NOCOLOUR}\] "
}
PROMPT_COMMAND='__setprompt' # Will run function every time a command is entered

HISTCONTROL=ignoreboth    # Don't put duplicate lines or lines starting with space in the history
HISTSIZE= HISTFILESIZE=   # Infinite history
stty -ixon                # Disable ctrl-s and ctrl-q.
shopt -s histappend       # Append to the history file, don't overwrite it
shopt -s cdspell dirspell # Minor error corrections on directories/files names
shopt -s checkwinsize     # Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
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
alias	cp='cp -iv' \
		mv='mv -iv' \
		rm='rm -v' \
		mkdir='mkdir -pv' \
		df='df -h' \
		free='free -h'

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

alias	ls='ls -h --color=auto --group-directories-first' \
		grep='grep --color=auto' \
		fgrep='fgrep --color=auto' \
		egrep='egrep --color=auto' \
		diff='diff --color=auto' \
		ip='ip --color=auto' \
		ll='ls -hClas --color=auto --group-directories-first'

# Print out escape sequences usable for coloured text on tty.
colours() {
	local fgc bgc vals seq0

	printf 'Colour escapes are %s\n' '\e[${value};...;${value}m'
	printf 'Values 30..37 are \e[33mforeground colours\e[m\n'
	printf 'Values 40..47 are \e[43mbackground colours\e[m\n'
	printf 'Value  1 gives a  \e[1mbold look\e[m\n'
	printf 'Value  2 gives a  \e[2mdim look\e[m\n'
	printf 'Value  3 gives a  \e[3mitalic look\e[m\n'
	printf 'Value  4 gives a  \e[4munderlined look\e[m\n'
	printf 'Value  5 gives a  \e[5mblinking look\e[m\n\n'

	# foreground colours
	for fgc in {30..37}; do
		# background colours
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf " %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
			printf " \e[${vals:+${vals+$vals;}}2mDIM\e[m"
			printf " \e[${vals:+${vals+$vals;}}3mITA\e[m"
			printf " \e[${vals:+${vals+$vals;}}4mUND\e[m"
			printf " \e[${vals:+${vals+$vals;}}5mBLI\e[m"
		done
		echo; echo
	done
}

# Simple command to preview csv files
preview_csv(){
	if [[ -z "$1" || "$1" == 'help' || "$1" == '--help' ]]; then
		echo "Usage : $FUNCNAME filename.csv"
		return 0
	elif [[ ! -r $1 ]]; then
		echo "Can't read file $1"
		return 1
	fi
	cat "$1" | sed 's/,/ ,/g' | column -t -s, | less -S -n
}

# Command and description display helper
print_cmd(){
	printf "\055 \e[${ITALIC}%-32s\e[${NOCOLOUR} : $2\n" "$1"
}

if command -v neofetch >> /dev/null; then
	neofetchupdate(){
		neofetch --config $XDG_CONFIG_HOME/neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	}
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetchupdate
	echo -e "\n$(cat $XDG_CACHE_HOME/.neofetch)${BOLD}Available commands :${NOCOLOUR}"
	print_cmd 'neofetchupdate' 'Update the cached neofetch informations'
else
	echo -e "${BOLD}Available commands :${NOCOLOUR}"
fi
if command -v python >> /dev/null; then
	# Activate the python virtual environment in the current folder
	activate(){
		if [[ "$1" == 'help' || "$1" == '--help' ]]; then
			echo "Use $FUNCNAME to enable the current folder's python virtual environment"
			return 0
		fi
		if [ -f venv/Scripts/activate ]; then source venv/Scripts/activate
		elif [ -f venv/bin/activate ]; then source venv/bin/activate
		else echo 'Python virtual environment not detected !'
		fi
	}
	print_cmd 'activate' 'Activate the python virtual environment'
fi
print_cmd 'colours' 'Show the colours palette of the current terminal'
print_cmd 'preview_csv <file>' 'Preview a csv file'
if command -v nvim >> /dev/null; then
	command -v nvim >> /dev/null && alias vi='nvim' vim='nvim' vid='nvim -d' vimdiff='nvim -d'
	#print_cmd 'vi or vim <file/directory/?>' 'Shortcut to nvim'
	print_cmd 'vid or vimdiff <file1> <file2>' 'Shortcut to nvim diff mode'
fi
print_cmd 'll <directory/?>' 'Detailed ls'
if command -v pacman >> /dev/null; then
	alias pacprune='pacman -Qtdq | sudo pacman -Rns -'
	print_cmd 'pacprune' 'Remove unused packages (orphans)'

	alias pacupdate='sudo pacman -Syu'
	print_cmd 'pacupdate' 'Update every packages'

	aur_install() {
		if [[ -z "$1" || "$1" == 'help' || "$1" == '--help' ]]; then
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
	print_cmd 'aur_install <git_link>' 'Install specified AUR package to AUR_PATH'

	aur_update() {
		local PACKAGE_NAME
		for PACKAGE_NAME in $(ls $AUR_PATH); do
			if [[ $(git -C $AUR_PATH/$PACKAGE_NAME pull) == 'Already up to date.' ]]; then
				echo Package $PACKAGE_NAME already up to date
			else
				echo Updating $PACKAGE_NAME
				cd $AUR_PATH/$PACKAGE_NAME
				makepkg -sri
				cd -
			fi
		done
	}
	print_cmd 'aur_update' 'Update every AUR packages'

	aur_uninstall() {
		if [[ -z "$1"  || "$1" == 'help' || "$1" == '--help' ]]; then
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
	print_cmd 'aur_uninstall <aur-package-name>' 'Uninstall a specified AUR package'

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
	print_cmd 'aur_list' 'List of the installed AUR packages'
fi
command -v xclip >> /dev/null && alias xclip='xclip -selection clipboard' && print_cmd 'xclip' 'Copy/Paste (with -o) from STDOUT to clipboard'
command -v openvpn >> /dev/null && alias vpn='sudo openvpn ~/.ssh/LinodeVPN.ovpn &' && print_cmd 'vpn' 'Easily enable a secure VPN connection'
command -v reflector >> /dev/null && alias update_mirrors='sudo reflector -a 48 -c $(curl -s ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist' && print_cmd 'update_mirrors' "Update pacman's mirrors"
command -v lazygit >> /dev/null && alias lg='lazygit' && print_cmd 'lg' 'Shortcut to lazygit, a fancy CLI git interface'

if command -v xrandr >> /dev/null; then
	alias hdmi_on='xrandr --output HDMI-1-0 --auto --left-of eDP1'
	print_cmd 'hdmi_on' 'Turn on the HDMI connection and put it on the left'
	alias hdmi_off='xrandr --output HDMI-1-0 --off'
	print_cmd 'hdmi_off' 'Turn off the HDMI connection'
fi

echo -e "${BOLD}\nBash bang shortcuts remainders :${NOCOLOUR}"
#print_cmd '!!' 'Last command'
#print_cmd '!$' 'Last item ran'
print_cmd '!^' 'First item ran'
print_cmd '!*' 'All items ran'
