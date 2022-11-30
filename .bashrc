#!/usr/bin/env bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set config and data folder for nvim, alacritty etc...
export XDG_CONFIG_HOME=$HOME/.XDG/config
export XDG_CACHE_HOME=$HOME/.XDG/cache
export XDG_DATA_HOME=$HOME/.XDG/data
export XDG_STATE_HOME=$HOME/.XDG/state
export XDG_RUNTIME_DIR=$HOME/.XDG/runtime

# Set extras dotfiles location to clean home (xdg-ninja)
command -v nvidia-settings >> /dev/null && alias nvidia-settings="nvidia-settings --config=\"$XDG_CONFIG_HOME/nvidia/settings\""
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

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

HISTCONTROL=ignoreboth                       # Don't put duplicate lines or lines starting with space in the history
HISTSIZE= HISTFILESIZE=                      # Infinite history
export HISTFILE=$XDG_STATE_HOME/bash/history # Change the default history file location
stty -ixon                                   # Disable ctrl-s and ctrl-q.
shopt -s histappend                          # Append to the history file, don't overwrite it
shopt -s cdspell dirspell                    # Minor error corrections on directories/files names
shopt -s expand_aliases                      # Enable the alias keyword

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

command -v wget >> /dev/null && alias wget="wget --hsts-file=\"$XDG_DATA_HOME=wget-hsts\""

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
	if [[ -z "$1" || "$1" == 'h' || "$1" == '-h' || "$1" == 'help' || "$1" == '--help' ]]; then
		echo "Usage : $FUNCNAME filename.csv"
		return 0
	elif [[ ! -r $1 ]]; then
		echo "Can't read file $1"
		return 1
	fi
	cat "$1" | sed 's/,/ ,/g' | column -t -s, | less -S -n
}

if command -v neofetch >> /dev/null; then
	nfu(){
		neofetch --config $XDG_CONFIG_HOME/neofetch/config.conf > $XDG_CACHE_HOME/.neofetch
	}
	test ! -r $XDG_CACHE_HOME/.neofetch && nfu
	echo -e -n "\n$(cat $XDG_CACHE_HOME/.neofetch)"
else
	echo -e "${BOLD}Available commands :${NOCOLOUR}"
fi

if command -v python >> /dev/null; then
	# Activate the python virtual environment in the current folder
	activate(){
		if [[ "$1" == 'h' || "$1" == '-h' || "$1" == 'help' || "$1" == '--help' ]]; then
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

# Little helper for missing packages
__command_requirer_pkg__(){
	if command -v $2 >> /dev/null; then
			bash -c "$1 $4"
		else
			echo "This command requires $2 from \"$3\" installed" && return 1
	fi
}

if command -v pacman >> /dev/null; then
	pac(){
		local USAGE="Pacman helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME u|update|upgrade\n\tUpdate every packages.\n\n
			\t$FUNCNAME m|mirrors\n\tUpdate the mirrorlist.\n\n
			\t$FUNCNAME p|prune\n\tRemove unused packages (orphans).\n\n
			\t$FUNCNAME h|-h|help|--help\n\tShow this help message"
		case "$1" in
			u|update|upgrade) sudo pacman -Syu ;;
			m|mirrors)
				__update_mirrors__(){
					local MIRRORFILE=/etc/pacman.d/mirrorlist
					test $(cat /etc/os-release | grep '^ID') = 'ID=artix' && MIRRORFILE+='-arch'
					sudo reflector -a 48 -c $(curl -s ifconfig.io/country_code) -f 5 -l 20 --sort rate --save $MIRRORFILE
				}
				export -f __update_mirrors__
				__command_requirer_pkg__ __update_mirrors__ reflector reflector
				;;
			p|prune) pacman -Qtdq | sudo pacman -Rns - ;;
			h|-h|--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}

	aur(){
		local AUR_PATH=$HOME/.aur
		local USAGE="AUR Install helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME i|install <aur-package-name>\n\tInstall the specified AUR package.\n\n
			\t$FUNCNAME r|remove|uninstall <aur-package-name>\n\tUninstall the specified AUR package.\n\n
			\t$FUNCNAME l|list\n\tList all the AUR packages.\n\n
			\t$FUNCNAME u|update|upgrade\n\tUpdate all the AUR packages.\n\n
			\t$FUNCNAME h|-h|help|--help\n\tShow this help message"
		case "$1" in
			i|install)
				if [[ -z "$2" || "$2" == 'h' || "$2" == '-h' || "$2" == 'help' || "$2" == '--help' ]]; then
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

			u|update|upgrade)
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

			r|remove|uninstall)
				if [[ -z "$2" || "$2" == 'h' || "$2" == '-h' || "$2" == 'help' || "$2" == '--help' ]]; then
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

			l|list)
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

			h|-h|--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}

fi

if command -v emerge >> /dev/null; then
	em(){
		local USAGE="Portage's emerge helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME s|sync\n\tSync the packages repository.\n\n
			\t$FUNCNAME u|update|upgrade\n\tUpdate every packages.\n\n
			\t$FUNCNAME l|list\n\tList every packages in the @world set.\n\n
			\t$FUNCNAME q|query\n\tSearch packages that contains a given file.\n\n
			\t$FUNCNAME c|clean\n\tClean the unused distfiles and packages remainders.\n\n
			\t$FUNCNAME p|prune\n\tRemove unused packages (orphans).\n\n
			\t$FUNCNAME d|desc\n\tList all possible USE variable.\n\n
			\t$FUNCNAME U|use\n\tList all set USE variable.\n\n
			\t$FUNCNAME m|mirrors\n\tUpdate the mirrorlist.\n\n
			\t$FUNCNAME h|-h|help|--help\n\tShow this help message"
		case "$1" in
			s|sync) sudo sh -c 'emerge --sync && command -v eix >> /dev/null && eix-update && eix-remote update' ;;
			u|update|upgrade) sudo sh -c 'command -v haskell-updater >> /dev/null && haskell-updater; emerge -UNDuq @world' ;;
			l|list) cat /var/lib/portage/world ;;
			q|query) __command_requirer_pkg__ e-file e-file app-portage/pfl "$2" ;;
			c|clean) __command_requirer_pkg__ 'sudo sh -c "eclean -d packages && eclean -d distfiles && echo \"Deleting portage temporary files\" && rm -r /var/tmp/portage/*"' eclean app-portage/gentoolkit ;;
			p|prune) sudo emerge -acD ;;
			d|desc) less /var/db/repos/gentoo/profiles/use.desc ;;
			U|use) __command_requirer_pkg__ 'portageq envvar USE | xargs -n1 | less' portageq sys-apps/portage ;;
			m|mirrors) sudo sh -c "sed -z -i 's/\\n\{,2\}GENTOO_MIRRORS=\".*\"\\n//g' /etc/portage/make.conf; mirrorselect -s 10 -o | sed -z 's/\\\\\n    //g' >> /etc/portage/make.conf" ;;
			h|-h|--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}
fi

command -v xclip >> /dev/null && alias xclip='xclip -selection clipboard'
command -v wg-quick >> /dev/null && alias vpn='sudo wg-quick up wg0' && alias vpn_off='sudo wg-quick down wg0'
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
			\t$FUNCNAME e|extend\n\tExtend the primary display to the secondary.\n\n
			\t$FUNCNAME m|mirror\n\tMirror the primary display to the secondary.\n\n
			\t$FUNCNAME o|off\n\tTurn off a display.\n\n
			\t$FUNCNAME h|-h|help|--help\n\tShow this help message"
		__get_display__(){
			xrandr | grep connected | awk "{ print \$1 }" | dmenu -p "$1 :" -l 20 -c
		}
		case "$1" in
			e|extend)
				local Primary=$(__get_display__ Primary)
				test -z $Primary&& return 0
				local Secondary=$(__get_display__ Secondary)
				test -z $Secondary && return 0
				local mode=$(echo -e 'right-of\nleft-of\nabove\nbelow' | dmenu -p 'Mode :' -c -l 20)
				xrandr --output $Secondary --auto --$mode $Primary
			;;
			m|mirror)
				local Primary=$(__get_display__ Primary)
				test -z $Primary&& return 0
				local Secondary=$(__get_display__ Secondary)
				test -z $Secondary && return 0
				xrandr --output $Secondary --auto --same-as $Primary
			;;
			o|off)
				local Primary=$(__get_display__ Primary)
				test -z $Primary && return 0
				xrandr --output $Primary --off
			;;
			h|-h|--help|help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}
fi

alias cb='clear && exec bash'
if command -v pactl >> /dev/null; then
	__moff__(){
		pactl unload-module module-native-protocol-tcp 2>>/dev/null
	}

	__soff__(){
		pactl unload-module module-tunnel-sink-new 2>>/dev/null
		pactl unload-module module-tunnel-source 2>>/dev/null
	}

	__paloopoff__(){
		pactl unload-module module-loopback 2>>/dev/null
	}

	pa(){
		local USAGE="Pulseaudio modules helper\nImplemented by @saundersp\n\nDocumentation:\n
			\t$FUNCNAME moff\n\tDisable master audio modules.\n\n
			\t$FUNCNAME m\n\tEnable master audio modules.\n\n
			\t$FUNCNAME soff\n\tDisable slave audio modules.\n\n
			\t$FUNCNAME s\n\tEnable slave audio modules.\n\n
			\t$FUNCNAME loopoff\n\tDisable audio loopback.\n\n
			\t$FUNCNAME loop [ms]\n\tEnable audio loopback.\n\n
			\t$FUNCNAME h|-h|help|--help\n\tShow this help message"
		case "$1" in
			moff) __moff__ ;;
			m)
				__moff__
				pactl load-module module-native-protocol-tcp listen=192.168.137.1 auth-ip-acl=192.168.137.0/24
			;;
			soff) __soff__ ;;
			s)
				__soff__
				pactl load-module module-tunnel-sink-new server=192.168.137.1
				pactl load-module module-tunnel-source server=192.168.137.1
			;;
			loopoff) __paloopoff__ ;;
			loop)
				__paloopoff__
				local source=$(pactl list sources | grep Na |  awk '{ print $2 }' | dmenu -p 'Source:' -c -l 10 )
				test -z $source && return 0
				local sink=$(pactl list sinks | grep Na |  awk '{ print $2 }' | dmenu -p 'Sink:' -c -l 10 )
				test -z $sink && return 0
				if [ -z $2 ]; then
					pactl load-module module-loopback sink="$sink" source="$source"
				else
					pactl load-module module-loopback sink="$sink" source="$source" latency_msec=$2
				fi
			;;
			h|-h|help|--help) echo -e $USAGE && return 0 ;;
			*) echo -e $USAGE && return 1 ;;
		esac
	}
	command -v pulsemixer >> /dev/null && alias pm='pulsemixer'
fi

command -v curl >> /dev/null && alias weather='curl de.wttr.in/valbonne'
test -d "$HOME/Calibre Library" && command -v rsync >> /dev/null && alias sync_books='rsync -aP ~/"Calibre Library"/* linode:~/"Calibre Library"/*'

pow(){
	# The script assumes that all availables cpus has the same governor
	local MODES=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)

	local USAGE="CPU scaling governor helper\nImplemented by @saundersp\n\nDocumentation:
	$FUNCNAME l|list|-l|--list\n\tList all the availables scaling governors.\n\n
	$FUNCNAME c|current|-c|--current\n\tDisplay the current selected scaling governor.\n\n
	$FUNCNAME $(echo "$MODES" | sed 's/ /|/')\n\tSet the scaling governor to argument name.\n\n
	$FUNCNAME h|help|-h|--help\n\tShow this help message"

	case "$1" in
		l|list|-l|--list) echo "$MODES" ;;
		c|current|-c|--current) cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ;;
		h|help|-h|--help) echo -e "$USAGE" && return 0 ;;
		*)
			if $(echo "$MODES" | grep -wq "$1"); then
				echo "$1" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >> /dev/null
			else
				echo -e "$USAGE"
				return 1
			fi
		;;
	esac
}

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
	tprint_cmd 'nfu' 'Update the cached neofetch informations'
	tprint_cmd 'activate' 'Activate the python virtual environment'
	tprint_cmd 'colours' 'Show the colours palette of the current terminal'
	tprint_cmd 'preview_csv <file>' 'Preview a csv file'
	tprint_cmd 'vi or vim <file/directory/?>' 'Shortcut to nvim'
	tprint_cmd 'vid or vimdiff <file1> <file2>' 'Shortcut to nvim diff mode'
	tprint_cmd 'll <directory/?>' 'Detailed ls'
	tprint_cmd 'pac' 'Pacman helper'
	tprint_cmd 'em' "Portage's emerge helper"
	tprint_cmd 'aur' 'AUR Install helper script'
	tprint_cmd 'xclip' 'Copy/Paste (with -o) from STDOUT to clipboard'
	tprint_cmd 'vpn' 'Easily enable a secure VPN connection'
	tprint_cmd 'vpn_off' 'Easily disable a VPN connection'
	tprint_cmd 'lg' 'Shortcut to lazygit, a fancy CLI git interface'
	tprint_cmd 'ldo' 'Shortcut to lazydocker, a fancy CLI docker interface'
	tprint_cmd 'ranger-cd / C-o' 'Modded ranger to changed pwd on exit'
	tprint_cmd 'hdmi' 'HDMI connection helper script'
	tprint_cmd 'cb' 'Shortcut to clear && exec bash'
	tprint_cmd 'pa' 'Pulseaudio modules helper script'
	tprint_cmd 'pm' 'Pulsemixer shortcut'
	tprint_cmd 'weather' 'Get current weather status'
	print_cmd 'pow' 'CPU scaling governor helper'
	tprint_cmd 'sync_books' "Sync calibre's books to the linode's VPS"
	print_cmd '?' 'Print this reminder'

	echo -e "${BOLD}\nBash bang shortcuts remainders :${NOCOLOUR}"
	print_cmd '!!' 'Last command'
	print_cmd '!$' 'Last item ran'
	print_cmd '!^' 'First item ran'
	print_cmd '!*' 'All items ran'
}
alias ?='__helpme__'
