#!/usr/bin/env bash

# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

# Set config and data folder for nvim, etc...
export XDG_CONFIG_HOME="$HOME"/.XDG/config
export XDG_CACHE_HOME="$HOME"/.XDG/cache
export XDG_DATA_HOME="$HOME"/.XDG/data
export XDG_STATE_HOME="$HOME"/.XDG/state
export XDG_RUNTIME_DIR="$HOME"/.XDG/runtime

# Some global XDG variables
if [ -d /opt/cuda ]; then
	export CUDA_HOME=/opt/cuda
	export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
fi

# Set extras dotfiles location to clean home (xdg-ninja)
export LESSHISTFILE="$XDG_STATE_HOME"/less_history
command -v gradle >> /dev/null && export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
command -v java >> /dev/null && export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
command -v gpg >> /dev/null && export GNUPGHOME="$XDG_DATA_HOME"/gnupg
command -v wine >> /dev/null && export WINEPREFIX="$XDG_DATA_HOME"/wine
command -v ipython >> /dev/null && export IPYTHONDIR="$XDG_CONFIG_HOME"/ipython
command -v go >> /dev/null && export GOPATH="$XDG_DATA_HOME"/go
command -v docker >> /dev/null && export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
command -v cargo >> /dev/null && export CARGO_HOME="$XDG_DATA_HOME"/cargo
if command -v pipx >> /dev/null; then
	export PIPX_BIN_DIR="$XDG_DATA_HOME/pipx/bin"
	export PIPX_MAN_DIR="$XDG_DATA_HOME/pipx/man"
	export PATH="$PATH:$PIPX_BIN_DIR"
fi

# Define colours
#LIGHTGRAY='\033[0;37m'
#WHITE='\033[1;37m'
#BLACK='\033[0;30m'
#DARKGRAY='\033[1;30m'
RED='\033[0;31m'
LIGHTRED='\033[1;31m'
#GREEN='\033[0;32m'
#LIGHTGREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
MAGENTA='\033[0;35m'
#LIGHTMAGENTA='\033[1;35m'
#CYAN='\033[0;36m'
#LIGHTCYAN='\033[1;36m'
NOCOLOUR='\033[0m'
USER_COLOUR="$LIGHTRED"

# Define text styles
BOLD='\033[1m'
#DIM='\033[2m'
ITALIC='\033[3m'
#UNDERLINED='\033[4m'
#BLINKING='\033[5m'

command -v "$1" >> /dev/null && echo 'Command checker has replaced __cmd_checker__ !'
__cmd_checker__(){
	while [ -n "$1" ]; do
		if command -v "$1" >> /dev/null; then
			echo "Command $1 has been replaced !"
		#else
		#	echo "Command $1 has not been replaced !"
		fi
		shift
	done
}

__cmd_checker__ __setprompt
__setprompt() {
	LAST_COMMAND="$?" # Must come first!

	PS1="\[${USER_COLOUR}\]┌──"
	# Show error exit code if there is one
	if [ $LAST_COMMAND != 0 ]; then
		PS1="$PS1(\[${LIGHTRED}\]ERROR\[${USER_COLOUR}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${USER_COLOUR}\])\n├──"
	fi

	# Time
	PS1="$PS1(\[${LIGHTBLUE}\]$(date +%I:%M:%S•%p)\[${USER_COLOUR}\])-"

	# User and hostname
	PS1="$PS1(\[${MAGENTA}\]\u@\h"

	# Current directory
	PS1="$PS1\[${USER_COLOUR}\])-(\[${BROWN}\]\w\[${USER_COLOUR}\])"

	# Git branch
	PS1="$PS1\[${BLUE}\]$(git branch 2>>/dev/null | sed -n 's/\* \(.*\)/ ( \1)/p')"

	# Python virtual environment
	PS1="$PS1\[${YELLOW}\]$(test -n "$VIRTUAL_ENV" >> /dev/null && echo " ( $(basename "$VIRTUAL_ENV"))")"

	# Skip to the next line
	PS1="$PS1\r\n\[${USER_COLOUR}\]└─>\[${NOCOLOUR}\] "

	# PS2 is used to continue a command using the \ character
	PS2="\[${USER_COLOUR}\]>\[${NOCOLOUR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4="\[${USER_COLOUR}\]+\[${NOCOLOUR}\] "
}
PROMPT_COMMAND='__setprompt' # Will run function every time a command is entered

HISTCONTROL=ignoreboth                         # Don't put duplicate lines or lines starting with space in the history
HISTSIZE='' HISTFILESIZE=''                    # Infinite history
export HISTFILE="$XDG_STATE_HOME"/bash_history # Change the default history file location
stty -ixon                                     # Disable ctrl-s and ctrl-q.
shopt -s histappend                            # Append to the history file, don't overwrite it
shopt -s cdspell dirspell                      # Minor error corrections on directories/files names
shopt -s expand_aliases                        # Enable the alias keyword

# Enable programmable completion features script by GNU (https://github.com/scop/bash-completion)
if [ -f /usr/share/bash-completion/bash_completion ]; then . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then . /etc/bash_completion
fi

# Enable fzf functionalities
if command -v fzf >> /dev/null; then
	test -f /usr/share/bash-completion/completions/fzf && . /usr/share/bash-completion/completions/fzf
	# CTRL-T, CTRL-R, and ALT-C
	test -f /usr/share/fzf/key-bindings.bash && . /usr/share/fzf/key-bindings.bash
fi

# Add better human readability by default to common commands
command -v df >> /dev/null && alias df='df -h'
command -v free >> /dev/null && alias free='free -h'
command -v mkdir >> /dev/null && alias mkdir='mkdir -p'

# Colourful man page
export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

if command -v eza >> /dev/null; then
	alias ls='eza -h --color=auto --group-directories-first'
	__cmd_checker__ ll
	alias ll='eza -hlas size --git --color=auto --group-directories-first'
elif command -v ls >> /dev/null; then
	alias ls='ls -h --color=auto --group-directories-first'
	__cmd_checker__ ll
	alias ll='ls -hlas --color=auto --group-directories-first'
fi
command -v gdb >> /dev/null && alias gdb='gdb -q'
command -v cuda-gdb >> /dev/null && alias cuda-gdb='cuda-gdb -q'
command -v grep >> /dev/null && alias grep='grep --color=auto'
command -v fgrep >> /dev/null && alias fgrep='fgrep --color=auto'
command -v egrep >> /dev/null && alias egrep='egrep --color=auto'
command -v diff >> /dev/null && alias diff='diff --color=auto'
command -v ip >> /dev/null && alias ip='ip --color=auto'
command -v wget >> /dev/null && alias wget="wget --hsts-file=$XDG_DATA_HOME/wget-hsts"
# Replace default cat command
command -v bat >> /dev/null && alias cat='bat'

# Simple command to preview csv files
__cmd_checker__ preview_csv
preview_csv(){
	DEL=','
	if [ -z "$1" ]|| [ "$1" = 'h' ]|| [ "$1" = '-h' ]|| [ "$1" = 'help' ]|| [ "$1" = '--help' ]; then
		echo 'Usage: preview_csv filename.csv'
		return 0
	elif [ ! -r "$1" ]; then
		echo "Can't read file $1"
		return 1
	fi
	(sed 's/,/ ,/g' | column -t -s "$DEL" | less -S -n) < "$1"
}

command -v fastfetch >> /dev/null && [[ $- == *i* ]] && fastfetch

if command -v python >> /dev/null; then
	# Activate the python virtual environment in the current folder
	__cmd_checker__ activate
	activate(){
		if [ "$1" = 'h' ]|| [ "$1" = '-h' ]|| [ "$1" = 'help' ]|| [ "$1" = '--help' ]; then
			echo "Usage: activate [h|-h|help|--help] to enable the current folder's python virtual environment"
		elif [ -f venv/Scripts/activate ]; then . venv/Scripts/activate
		elif [ -f venv/bin/activate ]; then . venv/bin/activate
		else echo 'Python virtual environment not detected !'; return 1
		fi
	}
fi

if command -v nvim >> /dev/null; then
	export EDITOR=nvim
	__cmd_checker__ vid vi
	command -v nvim >> /dev/null && alias vid='nvim -d' && alias vi='nvim'
fi

# Little helper for missing packages
__cmd_checker__ __command_requirer_pkg__
__command_requirer_pkg__(){
	if command -v "$2" >> /dev/null; then
			bash -c "$1 $4"
		else
			echo "This command requires $2 from \"$3\" installed" && return 1
	fi
}

if command -v pacman >> /dev/null; then
	__cmd_checker__ __update_arch_mirrors__
	__update_arch_mirrors__(){
		MIRRORFILE=/etc/pacman.d/mirrorlist
		test "$(grep '^ID' /etc/os-release)" = 'ID=artix' && MIRRORFILE="$MIRRORFILE-arch"
		reflector -a 48 -c "$(curl -s ifconfig.io/country_code)" -f 5 -l 20 --sort rate --save "$MIRRORFILE"
	}

	__cmd_checker__ pac
	pac(){
		USAGE='Pacman helper
Implemented by @saundersp

USAGE: pac FLAG
Available flags:
	-u, u, update, --update		Update every packages.
	-l, l, list, --list		List every installed packages.
	-m, m, mirrors, --mirrors	Update the mirrorlist.
	-p, p, prune, --prune		Remove unused packages (orphans).
	-h, h, help, --help		Show this help message'
		case "$1" in
			-u|u|update|--update) pacman -Syu ;;
			-l|l|list|--list) pacman -Qe ;;
			-m|m|mirrors|--mirrors) __command_requirer_pkg__ __update_arch_mirrors__ reflector reflector ;;
			-p|p|prune|--prune) pacman -Qtdq | pacman -Rns - ;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}

fi

if command -v emerge >> /dev/null; then
	__cmd_checker__ em
	em(){
		USAGE="Portage's emerge helper
Implemented by @saundersp

USAGE: em FLAG
Available flags:
	-s, s, sync, --sync		Sync the packages repository.
	-u, u, update, --update		Update every packages.
	-l, l, list, --list		List every packages in the @world set.
	-q, q, query, --query		Search packages that contains a given file (requires app-portage/pfl).
	-c, c, clean, --clean		Clean the unused distfiles and packages remainders (requires app-portage/gentoolkit).
	-p, p, prune, --prune		Remove unused packages (orphans).
	-d, d, desc, --desc		List all possible USE variable.
	-U, U, use, --use		List all set USE variable.
	-m, m, mirrors, --mirrors	Update the mirrorlist.
	-b, b, board, --board		Show the latest sync timestamp of the repositories.
	-h, h, help, --help		Show this help message."
		case "$1" in
			-s|s|sync|--sync) sh -c 'emerge --sync && command -v eix >> /dev/null && eix-update && eix-remote update' ;;
			-u|u|update|--update) sh -c 'command -v haskell-updater >> /dev/null && haskell-updater; emerge -uUDv --keep-going=y @world && emerge -v @preserved-rebuild && dispatch-conf' ;;
			-l|l|list|--list) cat /var/lib/portage/world ;;
			-q|q|query|--query) __command_requirer_pkg__ e-file e-file app-portage/pfl "$2" ;;
			-c|c|clean|--clean) __command_requirer_pkg__ 'sh -c "eclean -d packages && eclean -d distfiles && echo \"Deleting portage temporary files\" && find /var/tmp/portage -mindepth 1 -delete"' eclean app-portage/gentoolkit ;;
			-p|p|prune|--prune) emerge -acD ;;
			-d|d|desc|--desc) less /var/db/repos/gentoo/profiles/use.desc ;;
			-U|U|use|--use) __command_requirer_pkg__ 'portageq envvar USE | xargs -n1 | less' portageq sys-apps/portage ;;
			-m|m|mirrors|--mirrors) sh -c "sed -z -i 's/\\n\{,2\}GENTOO_MIRRORS=\".*\"\\n//g' /etc/portage/make.conf; mirrorselect -s 10 -o | sed -z 's/\\\\\n    //g' >> /etc/portage/make.conf" ;;
			-b|b|board|--board)
				if ! __command_requirer_pkg__ '' format_time saundersp/format_time; then
					return 1
				fi
				declare -a repos commits
				repo_len=15
				commit_len=16

				if [ ! -d /var/db/repos ] || [ -z "$(ls /var/db/repos)" ]; then
					echo 'No repositories found'
					return 0
				fi

				for repo in /var/db/repos/*; do
					repo_name=$(echo "$repo" | cut -d / -f 5)
					if [ -f "$repo"/metadata/timestamp ]; then
						repo_date=$(date --date="$(cat "$repo"/metadata/timestamp)" +%s)
					elif [ -f "$repo"/metadata/timestamp.x ]; then
						repo_date=$(cut "$repo"/metadata/timestamp.x -d ' ' -f 1)
					elif [ -f "$repo"/metadata/timestamp.chk ]; then
						repo_date=$(date --date="$(cat "$repo"/metadata/timestamp.chk)" +%s)
					elif [ -d "$repo"/.git ]; then
						repo_date=$(git -C "$repo" log -1 --format=%ct)
					else
						continue
					fi
					commit=$(format_time $(($(date +%s) - repo_date)))
					commits+=("$commit")
					if [ ${#commit} -gt "$commit_len" ]; then
						commit_len=${#commit}
					fi
					repos+=("$repo_name")
					if [ ${#repo_name} -gt "$repo_len" ]; then
						repo_len=${#repo_name}
					fi
				done

				# Surely there is a better way to do this inline
				__cmd_checker__ __r__
				__r__(){
					end="$1"
					for _ in $(seq 1 "$end") ; do
						printf '%s' "$2";
					done
				}

				# ┌ <=> \u250C		─ <=> \u2500		┐ <=> \u2510
				# ┬ <=> \u252C		│ <=> \u2502		└ <=> \u2514
				# ┘ <=> \u2518		┴ <=> \u2534		├ <=> \u251C
				# ┼ <=> \u253C		┤ <=> \u2524

				env printf "┌$(__r__ $((repo_len + 2)) ─)┬$(__r__ $((commit_len + 2)) ─)┐\n"
				env printf "│ %-${repo_len}s │ %-${commit_len}s │\n" 'Repository name' 'Last commit time'
				env printf "├$(__r__ $((repo_len + 2)) ─)┼$(__r__ $((commit_len + 2)) ─)┤\n"
				for ((i=0; i<${#repos[@]}; i++)); do
					env printf "│ %-${repo_len}s │ %-${commit_len}s │\n" "${repos[i]}" "${commits[i]}"
				done
				env printf "└$(__r__ $((repo_len + 2)) '─')┴$(__r__ $((commit_len + 2)) ─)┘\n"

				unset __r__
			;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}
fi

if command -v apt-get >> /dev/null; then
	__cmd_checker__ ap
	ap(){
		USAGE="APT's helper
Implemented by @saundersp

USAGE: ap FLAG
Available flags:
	-u, u, update, --update		Update every packages.
	-l, l, list, --list		List every installed packages.
	-q, q, query, --query		Search packages that contains a given file.
	-p, p, prune, --prune		Remove unused packages (orphans).
	-h, h, help, --help		Show this help message"
		case "$1" in
			-u|u|update|--update) sh -c 'apt-get update && apt-get upgrade -y' ;;
			-l|l|list|--list) apt-get list --installed | grep '\[installed\]' | awk '{ print($1, $2, $3) }' ;;
			-q|q|query|--query) __command_requirer_pkg__ apt-file apt-file apt-file "search $2" ;;
			-p|p|prune|--prune) apt-get autoremove -y ;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}
fi

command -v wg-quick >> /dev/null && alias vpn='wg-quick up wg0' && alias vpn_off='wg-quick down wg0'
command -v lazygit >> /dev/null && alias lg='lazygit'
command -v lazydocker >> /dev/null && alias ldo='lazydocker'
command -v lazynpm >> /dev/null && alias lpm='lazynpm'

if command -v yazi >> /dev/null; then
	__cmd_checker__ yazi-cd
	yazi-cd() {
		tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
		yazi "$@" --cwd-file="$tmp"
		if [ -f "$tmp" ]; then
			dir="$(cat "$tmp")"
			rm -f "$tmp" >> /dev/null
			if [ "$dir" ] && [ "$dir" != "$(pwd)" ]; then
				cd "$dir" || true
			fi
		fi
	}
	bind '"\C-o":"\C-wyazi-cd\C-m"'
elif command -v ranger >> /dev/null; then
	__cmd_checker__ ranger-cd
	ranger-cd() {
		tmp="$(mktemp -t 'ranger-cwd.XXXXXX')"
		ranger --choosedir="$tmp"
		if [ -f "$tmp" ]; then
			dir="$(cat "$tmp")"
			rm -f "$tmp" >> /dev/null
			if [ "$dir" ] && [ "$dir" != "$(pwd)" ]; then
				cd "$dir" || true
			fi
		fi
	}
	bind '"\C-o":"\C-wranger-cd\C-m"'
fi

__cmd_checker__ cb && alias cb='clear && exec bash'

command -v curl >> /dev/null && __cmd_checker__ weather && alias weather='curl de.wttr.in/valbonne'

__cmd_checker__ pow
pow(){
	# The script assumes that all available cpus has the same governor
	GOVERNORS_PATH=/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
	test ! -f "$GOVERNORS_PATH" && echo 'CPU governors file unavailable' && return 1
	MODES="$(cat "$GOVERNORS_PATH")"

	USAGE="CPU scaling governor helper
Implemented by @saundersp

USAGE: pow FLAG
Available flags:
	-l, l, list, --list		List all the available scaling governors.
	-c, c, current, --current	Display the current selected scaling governor.
	${MODES/ /, }		Set the scaling governor to argument name.
	-h, h, help, --help		Show this help message"

	case "$1" in
		-l|l|list|--list) echo "$MODES" ;;
		-c|c|current|--current) cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ;;
		-ħ|h|help|--help) echo "$USAGE" ;;
		*)
			if echo "$MODES" | grep -wq "$1"; then
				echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >> /dev/null
			else
				echo "$USAGE" && return 1
			fi
		;;
	esac
}

__cmd_checker__ update
update(){
	command -v em >> /dev/null && em s && em u && em p && em c
	command -v pac >> /dev/null && pac u && pac p
	command -v ap >> /dev/null && ap u && ap p
	(cd && ./updater.sh p)
	command -v nix-env >> /dev/null && nix-env -u
}

__cmd_checker__ __helpme__
__helpme__(){
	__cmd_checker__ print_cmd
	print_cmd(){
		printf "\055 ${ITALIC}%-32s${NOCOLOUR} : $2\n" "$1"
	}

	__cmd_checker__ tprint_cmd
	tprint_cmd(){
		if command -v "$1" >> /dev/null; then
			print_cmd "$1 $3" "$2"
		#else
		#	printf "\055 ${ITALIC}%-32s${NOCOLOUR} : ${BOLD}This command isn't enabled${NOCOLOUR}\n" "$1"
		fi
	}

	echo -e "${BOLD}Available commands :${NOCOLOUR}"
	tprint_cmd 'activate' 'Activate the python virtual environment'
	tprint_cmd 'preview_csv' 'Preview a csv file' '<file>'
	tprint_cmd 'vid' 'Shortcut to nvim diff mode' '<file1> <file2>'
	tprint_cmd 'll' 'Detailed ls' '<directory>'
	tprint_cmd 'pac' 'Pacman helper'
	tprint_cmd 'em' "Portage's emerge helper"
	tprint_cmd 'ap' "APT's helper"
	tprint_cmd 'xclip' 'Copy/Paste (with -o) from STDOUT to clipboard'
	tprint_cmd 'vpn' 'Easily enable a secure VPN connection'
	tprint_cmd 'vpn_off' 'Easily disable a VPN connection'
	tprint_cmd 'lg' 'Shortcut to lazygit, a fancy CLI git interface'
	tprint_cmd 'ldo' 'Shortcut to lazydocker, a fancy CLI docker interface'
	tprint_cmd 'lpm' 'Shortcut to lazynpm, a fancy CLI npm interface'
	tprint_cmd 'yazi-cd' 'Modded yazi to changed pwd on exit' '/ C-o'
	tprint_cmd 'ranger-cd' 'Modded ranger to changed pwd on exit' '/ C-o'
	tprint_cmd 'hdmi' 'HDMI connection helper script'
	print_cmd 'cb' 'Shortcut to clear && exec bash'
	tprint_cmd 'pa' 'Pulseaudio modules helper script'
	tprint_cmd 'pm' 'Pulsemixer shortcut'
	tprint_cmd 'weather' 'Get current weather status'
	print_cmd 'pow' 'CPU scaling governor helper'
	print_cmd '?' 'Print this reminder'

	echo -e "${BOLD}\nBash bang shortcuts remainders :${NOCOLOUR}"
	print_cmd '!!' 'Last command'
	print_cmd '!$' 'Last item ran'
	print_cmd '!^' 'First item ran'
	print_cmd '!*' 'All items ran'

	unset print_cmd tprint_cmd
}
__cmd_checker__ '?'
alias '?'='__helpme__'
