#!/usr/bin/env bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set config and data folder for nvim, alacritty etc...
export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
AUR_PATH=$HOME/aur

# Define colours
#LIGHTGRAY='\033[0;37m'
#WHITE='\033[1;37m'
#BLACK='\033[0;30m'
DARKGRAY='\033[1;30m'
RED='\033[0;31m'
LIGHTRED='\033[1;31m'
#GREEN='\033[0;32m'
#LIGHTGREEN='\033[1;32m'
#BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
MAGENTA='\033[0;35m'
#LIGHTMAGENTA='\033[1;35m'
#CYAN='\033[0;36m'
#LIGHTCYAN='\033[1;36m'
NOCOLOUR='\033[0m'
USER_COLOUR=$DARKGRAY

# Define text styles
BOLD='\033[1m'
#DIM='\033[2m'
ITALIC='\033[3m'
#UNDERLINED='\033[4m'
#BLINKING='\033[5m'

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

	# Window title
	PS1+="\033]0;st (\w)\007"

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

# Add interactivity to common commands
alias	cp='cp -i' \
	mv='mv -i' \
	mkdir='mkdir -p' \
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

if command -v neofetch >> /dev/null; then
	neofetchupdate(){
		neofetch --config $XDG_CONFIG_HOME/neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	}
	test ! -r $XDG_CACHE_HOME/.neofetch && neofetchupdate
	echo -e -n "\n$(cat $XDG_CACHE_HOME/.neofetch)"
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
fi

if command -v nvim >> /dev/null; then
	export EDITOR=nvim
	command -v nvim >> /dev/null && alias vi='nvim' vim='nvim' vid='nvim -d' vimdiff='nvim -d'
fi

if command -v pacman >> /dev/null; then
	pac(){
		local USAGE="Pacman helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME update|upgrade\n\tUpdate every packages.\n\n
			\t$FUNCNAME prune\n\tRemove unused packages (orphans).\n\n
			\t$FUNCNAME help|--help\n\tShow this help message"
		case "$1" in
			update|upgrade) sudo pacman -Syu ;;
			prune) pacman -Qtdq | sudo pacman -Rns - ;;
			--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}

	aur(){
		local USAGE="AUR Install helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME install <aur-package-name>\n\tInstall the specified AUR package.\n\n
			\t$FUNCNAME uninstall <aur-package-name>\n\tUninstall the specified AUR package.\n\n
			\t$FUNCNAME list\n\tList all the AUR packages.\n\n
			\t$FUNCNAME update|upgrade\n\tUpdate all the AUR packages.\n\n
			\t$FUNCNAME help|--help\n\tShow this help message"
		case "$1" in
			install)
				if [[ -z "$2" || "$2" == 'help' || "$2" == '--help' ]]; then
					echo "Usage : $0 $1 install <aur-package-name>"
					return 0
				fi
				local PACKAGE_NAME=$2
				echo Package name : $PACKAGE_NAME
				test ! -d $AUR_PATH/$PACKAGE_NAME && git clone https://aur.archlinux.org/$PACKAGE_NAME.git $AUR_PATH/$PACKAGE_NAME
				cd $AUR_PATH/$PACKAGE_NAME
				local GPG_KEY=$(cat PKGBUILD | grep validpgpkeys | cut -d "'" -f 2)
				test ! -z $GPG_KEY && gpg --recv-keys $GPG_KEY
				makepkg -sri
				cd -
				;;

			update|upgrade)
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
			;;

			uninstall)
				if [[ -z "$2"  || "$2" == 'help' || "$2" == '--help' ]]; then
					echo "Usage : $0 $1 <aur-package-name"
					return 0
				fi
				local PACKAGE_NAME=$2
				if [[ ! -d $AUR_PATH/$PACKAGE_NAME ]]; then
					echo No such package : $PACKAGE_NAME
					return 1
				fi
				sudo pacman -Rns $PACKAGE_NAME
				rm -rf $AUR_PATH/$PACKAGE_NAME
				echo Uninstalled $PACKAGE_NAME successfully
				;;

			list)
				local PACKAGE_NAME PACMAN_INFO
				for PACKAGE_NAME in $(ls $AUR_PATH); do
					PACMAN_INFO=$(pacman -Q $PACKAGE_NAME 2>>/dev/null)
					if [[ ! -z $PACMAN_INFO ]]; then
						echo - [x] $PACMAN_INFO
					else
						echo - [ ] $PACKAGE_NAME
					fi
				done
			;;

			--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}

fi

command -v xclip >> /dev/null && alias xclip='xclip -selection clipboard'
command -v openvpn >> /dev/null && alias vpn='sudo openvpn ~/.ssh/LinodeVPN.ovpn &'
if command -v reflector >> /dev/null; then
	update_mirrors(){
		local MIRRORFILE=/etc/pacman.d/mirrorlist
		test $(cat /etc/os-release | grep '^ID') = 'ID=artix' && MIRRORFILE+='-arch'
		sudo reflector -a 48 -c $(curl -s ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
	}
fi
command -v lazygit >> /dev/null && alias lg='lazygit'
command -v lazydocker >> /dev/null && alias ldo='lazydocker'

if command -v ranger >> /dev/null; then
	ranger-cd() {
		local tmp="$(mktemp)"
		ranger --choosedir=$tmp
		if [ -f "$tmp" ]; then
			local dir="$(cat "$tmp")"
			rm -f "$tmp" >> /dev/null
			if [ "$dir" ] && [ "$dir" != "$(pwd)" ]; then
				cd "$dir"
			fi
		fi
	}
	bind '"\C-o":"ranger-cd\C-m"'
fi

if command -v xrandr >> /dev/null; then
	hdmi(){
		local USAGE="HDMI connection helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME left\n\tEnable the hdmi connection and put it on the left.\n\n
			\t$FUNCNAME right\n\tEnable the hdmi connection and put it on the right.\n\n
			\t$FUNCNAME help|--help\n\tShow this help message"
		case "$1" in
			left) xrandr --output HDMI-1-0 --auto --left-of eDP1 ;;
			right) xrandr --output HDMI-1-0 --auto --right-of eDP1 ;;
			off) xrandr --output HDMI-1-0 --off ;;
			--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}
fi

alias cb='clear && exec bash'
if command -v pactl >> /dev/null; then
	__rpoff__(){
		pactl unload-module module-native-protocol-tcp
	}

	__rsoff__(){
		pactl unload-module module-tunnel-sink
		pactl unload-module module-tunnel-source
	}

	__paloopoff__(){
		pactl unload-module module-loopback
	}

	pa(){
		local USAGE="Pulseaudio modules helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME poff\n\tDisable master audio modules.\n\n
			\t$FUNCNAME p\n\tEnable master audio modules.\n\n
			\t$FUNCNAME roff\n\tDisable slave audio modules.\n\n
			\t$FUNCNAME r\n\tEnable slave audio modules.\n\n
			\t$FUNCNAME loopoff\n\tDisable audio loopback.\n\n
			\t$FUNCNAME loop\n\tEnable audio loopback.\n\n
			\t$FUNCNAME help|--help\n\tShow this help message"
		case "$1" in
			poff) __rpoff__ ;;
			p)
				__rpoff__
				pactl load-module module-native-protocol-tcp listen=192.168.137.1 auth-ip-acl=192.168.137.0/24
			;;
			roff) __rsoff ;;
			r)
				__rsoff__
				pactl load-module module-tunnel-sink server=192.168.137.1
				pactl load-module module-tunnel-source server=192.168.137.1
			;;
			loopoff) __paloopoff__ ;;
			loop)
				__paloopoff__
				pactl load-module module-loopback sink=alsa_output.pci-0000_00_1f.3.analog-stereo source=alsa_input.pci-0000_00_1f.3.analog-stereo
			;;
			--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}
fi

alias weather='curl de.wttr.in/valbonne'

__helpme__(){
	print_cmd(){
		printf "\055 \e[${ITALIC}%-32s\e[${NOCOLOUR} : $2\n" "$1"
	}

	tprint_cmd(){
		if command -v $1 >> /dev/null; then
			print_cmd "$1" "$2"
		#else
		#	echo The command $1 doesn\'t exists !
		fi
	}

	echo -e "${BOLD}Available commands :${NOCOLOUR}"
	tprint_cmd 'neofetchupdate' 'Update the cached neofetch informations'
	tprint_cmd 'activate' 'Activate the python virtual environment'
	tprint_cmd 'colours' 'Show the colours palette of the current terminal'
	tprint_cmd 'preview_csv <file>' 'Preview a csv file'
	tprint_cmd 'vi or vim <file/directory/?>' 'Shortcut to nvim'
	tprint_cmd 'vid or vimdiff <file1> <file2>' 'Shortcut to nvim diff mode'
	tprint_cmd 'll <directory/?>' 'Detailed ls'
	tprint_cmd 'pac' 'Pacman helper'
	tprint_cmd 'aur' 'AUR Install helper script'
	tprint_cmd 'xclip' 'Copy/Paste (with -o) from STDOUT to clipboard'
	tprint_cmd 'vpn' 'Easily enable a secure VPN connection'
	tprint_cmd 'update_mirrors' "Update pacman's mirrors"
	tprint_cmd 'lg' 'Shortcut to lazygit, a fancy CLI git interface'
	tprint_cmd 'ldo' 'Shortcut to lazydocker, a fancy CLI docker interface'
	tprint_cmd 'ranger-cd / C-o' 'Modded ranger to changed pwd on exit'
	tprint_cmd 'hdmi' 'HDMI connection helper script'
	tprint_cmd 'cb' 'Shortcut to clear && exec bash'
	tprint_cmd 'pa' 'Pulseaudio modules helper script'
	tprint_cmd 'weather' 'Get current weather status'
	tprint_cmd '?' 'Print this reminder'

	echo -e "${BOLD}\nBash bang shortcuts remainders :${NOCOLOUR}"
	print_cmd '!!' 'Last command'
	print_cmd '!$' 'Last item ran'
	print_cmd '!^' 'First item ran'
	print_cmd '!*' 'All items ran'
}
alias ?='__helpme__'
