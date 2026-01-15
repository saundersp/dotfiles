#!/usr/bin/env bash

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
NO_COLOUR='\033[0m'
USER_COLOUR="$LIGHTRED"

# Define text styles
BOLD='\033[1m'
#DIM='\033[2m'
ITALIC='\033[3m'
#UNDERLINED='\033[4m'
#BLINKING='\033[5m'

command -v cmd_check > /dev/null && echo 'Command cmd_check has replaced !'
cmd_check(){
	command -v "$1" > /dev/null
}

cmd_check __cmd_checker__ && echo 'Command __cmd_checker__ has replaced !'
__cmd_checker__(){
	local code=0
	while [ -n "$1" ]; do
		if cmd_check "$1"; then
			code=$((code + 1))
			echo "Command $1 has been replaced !"
		#else
		#	echo "Command $1 has not been replaced !"
		fi
		shift
	done
	return "$code"
}

# Little helper for missing packages
__cmd_checker__ __command_requirer_pkg__
__command_requirer_pkg__(){
	if cmd_check "$2"; then
			bash --login -c "$1 $4"
		else
			echo "This command requires $2 from \"$3\" installed" && return 1
	fi
}

# Enabling login by default
alias bash='bash --login'

# Add better human readability by default to common commands
cmd_check df && alias df='df --human-readable'
cmd_check free && alias free='free --human'
cmd_check mkdir && alias mkdir='mkdir --parents'

# Colourful man page
export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

if cmd_check eza; then
	alias ls='eza --header --color auto --group-directories-first'
	__cmd_checker__ ll
	alias ll='eza --header --long --all --sort size --git --color auto --group-directories-first'
elif cmd_check ls; then
	alias ls='ls --human-readable --color=auto --group-directories-first'
	__cmd_checker__ ll
	alias ll='ls --human-readable --all -l --size --color=auto --group-directories-first'
fi
cmd_check gdb && alias gdb='gdb --quiet'
cmd_check cuda-gdb && alias cuda-gdb='cuda-gdb --quiet'
cmd_check grep && alias grep='grep --color=auto'
cmd_check diff && alias diff='diff --color=auto'
cmd_check ip && alias ip='ip --color=auto'
cmd_check bat && alias cat='bat --tabs 8'
cmd_check ncdu && alias ncdu='ncdu --color dark --threads $(nproc)'
cmd_check su && alias su='su --login'

if cmd_check fzf; then
	export FZF_DEFAULT_OPTS='--walker-skip .git,node_modules,build,dosdevices,drive_c'

	export FZF_CTRL_R_OPTS='--bind esc:print-query'

	FZF_CTRL_T_OPTS='--walker file,dir,follow'
	if cmd_check bat; then
		export FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --preview 'head --lines 30 {} | bat --tabs 8 --number --color always'"
	else
		export FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --preview 'head --lines 30 {} | cat --number'"
	fi

	FZF_ALT_C_OPTS='--walker dir,follow'
	if cmd_check eza; then
		export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --preview 'eza --tree --colour always {}'"
	else
		export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --preview 'ls {}'"
	fi

	# CTRL-T, CTRL-R, and ALT-C
	eval "$(fzf --bash)"
fi

# Simple command to preview csv files
__cmd_checker__ preview_csv
preview_csv(){
	local DEL=','
	if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
		echo 'Usage: preview_csv [-d|--delim <delim>] filename.csv'
		return 0
	elif [ "$1" = '-d' ] || [ "$1" = '--delim' ]; then
		if [ -z "$2" ]; then
			echo 'Missing delimiter'
			return 1
		fi
		DEL="$2"
		shift 2
	fi
	if [ ! -r "$1" ]; then
		echo "Can't read file $1"
		return 1
	fi
	(head --lines 50 | column --table --separator "$DEL" | less --chop-long-lines --line-numbers) < "$1"
}

if cmd_check python; then
	USAGE="Python virtual environment helper
Implemented by @saundersp

USAGE: py FLAG
Available flags:
	-a, a, activate, --activate		Activate the virtual environment in the current folder.
	-c, c, create, --create			Create and enable a virtual environment in the current folder.
	-u, u, update, --update			Update every dependencies in the requirements.txt file.
	-U, U, uninstall, --uninstall		Remove the virtual environment in the current folder.
	-r, r, requirements, --requirements	Compare the installed packages version with those included in the requirements.txt file.
	-h, h, help, --help			Show this help message."

	VENV_PATH='./.venv'

	__cmd_checker__ py
	py(){
		case "$1" in
			-a|a|activate|--activate)
				if [ -f "$VENV_PATH"/Scripts/activate ]; then source "$VENV_PATH"/Scripts/activate
				elif [ -f "$VENV_PATH"/bin/activate ]; then source "$VENV_PATH"/bin/activate
				else
					if [ -f requirements.txt ]; then
						echo 'Python virtual environment not detected but a requirements.txt is found'
						read -r -p 'Install a Python virtual environment ? (Y/N): ' ANS && [[ "$ANS" == [yY] || "$ANS" == [yY][eE][sS] ]] || return 1
						py create
					else
						echo 'No Python virtual environment or requirements.txt detected'
						return 1
					fi
				fi
			;;
			-c|c|create|--create)
				if [ -d "$VENV_PATH" ]; then
					echo 'A python environment already exists'
					read -r -p 'Reinstall ? (Y/N): ' ANS && [[ "$ANS" == [yY] || "$ANS" == [yY][eE][sS] ]] || return 1
					py uninstall
				fi
				if [ ! -f requirements.txt ]; then
					echo 'Cannot create venv : Missing requirements.txt file'
					return 1
				fi

				echo 'Creating Python virtual environment...'
				python -m venv --upgrade-deps "$VENV_PATH"
				echo 'Activating Python virtual environment...'
				py activate
				echo 'Installing requirements...'
				pip install --requirement requirements.txt
			;;
			-u|u|update|--update)
				if [ ! -d "$VENV_PATH" ]; then
					echo 'Python virtual environment not detected but a requirements.txt is found'
					read -r -p 'Install a Python virtual environment with updated requirements ? (Y/N): ' ANS && [[ "$ANS" == [yY] || "$ANS" == [yY][eE][sS] ]] || return 1
					echo 'Creating Python virtual environment with updated dependencies...'
					python -m venv --upgrade-deps "$VENV_PATH"
					echo 'Activating Python virtual environment...'
					py activate
					echo 'Installing with updated requirements...'
					grep --regexp '^[^#]' requirements.txt | cut --delimiter = --fields 1 | xargs pip install --upgrade
					return 0
				elif [ ! -f requirements.txt ]; then
					echo 'Cannot update virtual environment : Missing requirements.txt file'
					return 1
				elif [ -n "$VIRTUAL_ENV" ] || [ -d "$VENV_PATH" ]; then
					echo 'Assuming to update the local environment'
					py activate
				fi

				echo 'Updating requirements...'
				grep --regexp '^[^#]' requirements.txt | cut --delimiter = --fields 1 | xargs pip install --upgrade
			;;
			-U|U|uninstall|--uninstall)
				if [ -n "$VIRTUAL_ENV" ]; then
					echo 'Deactivating Python virtual environment...'
					deactivate
				fi
				echo 'Uninstalling Python virtual environment...'
				rm --recursive --force "$VENV_PATH"
				echo 'Done.'
			;;
			-r|r|requirements|--requirements)
				if ! __command_requirer_pkg__ '' nvim app-editors/neovim; then
					return 1
				fi
				if [ ! -f requirements.txt ]; then
					echo 'Cannot fetch packages version : Missing requirements.txt file'
					return 1
				elif [ -z "$VIRTUAL_ENV" ] || [ -d "$VENV_PATH" ]; then
					echo 'Assuming to update the local environment'
					py activate
				fi

				TEMP_FILE=$(mktemp)
				pip freeze | grep --extended-regexp "($(grep --regexp '^[^#]' requirements.txt | cut --delimiter = --fields 1 | paste --serial --delimiters \|))=" > "$TEMP_FILE"
				nvim -d requirements.txt "$TEMP_FILE"
			;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}
fi

if cmd_check nvim; then
	test -z "$EDITOR" && export EDITOR=nvim
	__cmd_checker__ vid
	alias vid='nvim -d'
	! cmd_check vi && alias vi='nvim'
fi

if cmd_check pacman; then
	__cmd_checker__ pac
	pac(){
		local USAGE='Pacman helper
Implemented by @saundersp

USAGE: pac FLAG
Available flags:
	-u, u, update, --update		Update every packages.
	-l, l, list, --list		List every installed packages.
	-m, m, mirrors, --mirrors	Update the mirrorlist.
	-p, p, prune, --prune		Remove unused packages (orphans).
	-h, h, help, --help		Show this help message'
		case "$1" in
			-u|u|update|--update) pacman --sync --refresh --sysupgrade ;;
			-l|l|list|--list) pacman --query --explicit ;;
			-m|m|mirrors|--mirrors)
				if ! __command_requirer_pkg__ '' reflector reflector; then
					return 1
				fi
				local MIRRORFILE=/etc/pacman.d/mirrorlist
				test "$(grep '^ID' /etc/os-release)" = 'ID=artix' && MIRRORFILE="$MIRRORFILE-arch"
				reflector --age 48 --country "$(curl --silent ifconfig.io/country_code)" --fastest 5 --latest 20 --sort rate --save "$MIRRORFILE"
				;;
			-p|p|prune|--prune) pacman --query --unrequired --deps --quiet | pacman --remove --nosave --recursive - ;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}

fi

if cmd_check emerge; then
	__cmd_checker__ em
	em(){
		local USAGE="Portage's emerge helper
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
			-s|s|sync|--sync) env bash --login -c 'emerge --sync; if cmd_check eix; then eix-update && eix-remote update; fi' ;;
			-u|u|update|--update) env bash --login -c '
				cmd_check haskell-updater && haskell-updater
				emerge --update --newuse --deep --verbose --changed-use --keep-going y @world && emerge --verbose @preserved-rebuild && dispatch-conf
			' ;;
			-l|l|list|--list) cat /var/lib/portage/world ;;
			-q|q|query|--query) __command_requirer_pkg__ e-file e-file app-portage/pfl "$2" ;;
			-c|c|clean|--clean) __command_requirer_pkg__ 'sh -c "
				eclean --deep packages && eclean --deep distfiles && echo \"Deleting portage temporary files\" && find /var/tmp/portage -mindepth 1 -delete"' \
				eclean app-portage/gentoolkit ;;
			-p|p|prune|--prune) emerge --ask --depclean --deep ;;
			-d|d|desc|--desc) less /var/db/repos/gentoo/profiles/use.desc ;;
			-U|U|use|--use) __command_requirer_pkg__ 'portageq envvar USE | xargs --max-args 1 | less' portageq sys-apps/portage ;;
			-m|m|mirrors|--mirrors)
				if ! __command_requirer_pkg__ '' mirrorselect app-portage/mirrorselect; then
					return 1
				fi
				sh -c "cp /etc/portage/make.conf /etc/portage/make.conf.bak && sed --null-data --in-place 's/\\n\{,2\}GENTOO_MIRRORS=\".*\"\\n//g' /etc/portage/make.conf; mirrorselect --servers 10 --output | sed --null-data 's/\\\\\n    //g' >> /etc/portage/make.conf"
			;;
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
					repo_name=$(echo "$repo" | cut --delimiter / --fields 5)
					if [ -f "$repo"/metadata/timestamp ]; then
						repo_date=$(date --date "$(cat "$repo"/metadata/timestamp)" +%s)
					elif [ -f "$repo"/metadata/timestamp.x ]; then
						repo_date=$(cut "$repo"/metadata/timestamp.x --delimiter ' ' --fields 1)
					elif [ -f "$repo"/metadata/timestamp.chk ]; then
						repo_date=$(date --date "$(cat "$repo"/metadata/timestamp.chk)" +%s)
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
					local end="$1"
					for _ in $(seq 1 "$end") ; do
						printf '%s' "$2";
					done
				}

				# ┌ <=> \u250C		─ <=> \u2500		┐ <=> \u2510
				# ┬ <=> \u252C		│ <=> \u2502		└ <=> \u2514
				# ┘ <=> \u2518		┴ <=> \u2534		├ <=> \u251C
				# ┼ <=> \u253C		┤ <=> \u2524

				printf "┌$(__r__ $((repo_len + 2)) ─)┬$(__r__ $((commit_len + 2)) ─)┐\n"
				printf "│ %-${repo_len}s │ %-${commit_len}s │\n" 'Repository name' 'Last commit time'
				printf "├$(__r__ $((repo_len + 2)) ─)┼$(__r__ $((commit_len + 2)) ─)┤\n"
				for ((i=0; i<${#repos[@]}; i++)); do
					printf "│ %-${repo_len}s │ %-${commit_len}s │\n" "${repos[i]}" "${commits[i]}"
				done
				printf "└$(__r__ $((repo_len + 2)) '─')┴$(__r__ $((commit_len + 2)) ─)┘\n"

				unset __r__
			;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}
fi

if cmd_check apt-get; then
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
			-u|u|update|--update) sh -c 'apt-get update && apt-get upgrade --yes' ;;
			-l|l|list|--list) apt list --installed | grep '\[installed\]' | awk '{ print($1, $2, $3) }' ;;
			-q|q|query|--query) __command_requirer_pkg__ apt-file apt-file apt-file "search $2" ;;
			-p|p|prune|--prune) apt-get autoremove --yes ;;
			-h|h|help|--help) echo "$USAGE" ;;
			*) echo "$USAGE" && return 1 ;;
		esac
	}
fi

cmd_check lazygit && alias lg='lazygit'
cmd_check lazydocker && alias ldo='lazydocker'
__cmd_checker__ cb && alias cb='clear && exec bash'

__cmd_checker__ pow
pow(){
	# The script assumes that all available cpus has the same governor
	local GOVERNORS_PATH=/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
	test ! -f "$GOVERNORS_PATH" && echo 'CPU governors file unavailable' && return 1
	local MODES
	MODES="$(cat $GOVERNORS_PATH)"

	local USAGE="CPU scaling governor helper
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
			if echo "$MODES" | grep --word-regexp --quiet "$1"; then
				echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
			else
				echo "$USAGE" && return 1
			fi
		;;
	esac
}

__cmd_checker__ update
update(){
	cmd_check em && em sync && em update && em prune && em clean
	cmd_check pac && pac update && pac prune
	cmd_check ap && ap update && ap prune
	(cd && ./updater.sh packages)
	cmd_check ncu && npm update --global npm-check-updates
}

__cmd_checker__ __help_me__
__help_me__(){
	__cmd_checker__ print_cmd
	print_cmd(){
		printf "\055 ${ITALIC}%-32s${NO_COLOUR} : $2\n" "$1"
	}

	__cmd_checker__ tprint_cmd
	tprint_cmd(){
		if cmd_check "$1"; then
			print_cmd "$1 $3" "$2"
		#else
		#	printf "\055 ${ITALIC}%-32s${NO_COLOUR} : ${BOLD}This command isn't enabled${NO_COLOUR}\n" "$1"
		fi
	}

	echo -e "${BOLD}Available commands :${NO_COLOUR}"
	tprint_cmd 'py' 'Python virtual environment helper'
	tprint_cmd 'preview_csv' 'Preview a csv file' '<file>'
	tprint_cmd 'vid' 'Shortcut to nvim diff mode' '<file1> <file2>'
	tprint_cmd 'll' 'Detailed ls' '<directory>'
	tprint_cmd 'pac' 'Pacman helper'
	tprint_cmd 'em' "Portage's emerge helper"
	tprint_cmd 'ap' "APT's helper"
	tprint_cmd 'lg' 'Shortcut to lazygit, a fancy CLI git interface'
	tprint_cmd 'ldo' 'Shortcut to lazydocker, a fancy CLI docker interface'
	tprint_cmd 'yazi-cd' 'Modded yazi to changed pwd on exit' '/ C-o'
	tprint_cmd 'hdmi' 'HDMI connection helper script'
	print_cmd 'cb' 'Shortcut to clear && exec bash'
	tprint_cmd 'pa' 'Pulseaudio modules helper script'
	tprint_cmd 'pm' 'Pulsemixer shortcut'
	print_cmd 'pow' 'CPU scaling governor helper'
	print_cmd '?' 'Print this reminder'

	echo -e "${BOLD}\nBash bang shortcuts remainders :${NO_COLOUR}"
	print_cmd '!!' 'Last command'
	print_cmd '!$' 'Last item ran'
	print_cmd '!^' 'First item ran'
	print_cmd '!*' 'All items ran'

	unset print_cmd tprint_cmd
}
__cmd_checker__ '?'
alias '?'='__help_me__'

# Interactive only options
if [[ $- == *i* ]]; then
	export HISTCONTROL=ignoredups                  # Don't put duplicate lines
	export HISTSIZE=-1 HISTFILESIZE=-1             # Infinite history
	export HISTFILE="$XDG_STATE_HOME"/bash_history # Change the default history file location
	stty -ixon                                     # Disable ctrl-s and ctrl-q.
	shopt -s histappend                            # Append to the history file, don't overwrite it
	shopt -s cdspell dirspell                      # Minor error corrections on directories/files names

	# Enable programmable completion features script by GNU (https://github.com/scop/bash-completion)
	test -f /usr/share/bash-completion/bash_completion && source /usr/share/bash-completion/bash_completion

	__cmd_checker__ __setprompt
	__setprompt() {
		local LAST_COMMAND="$?" # Must come first!

		PS1="\[${USER_COLOUR}\]┌──"
		# Show error exit code if there is one
		if [ $LAST_COMMAND != 0 ]; then
			PS1="$PS1(\[${LIGHTRED}\]ERROR\[${USER_COLOUR}\])─(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${USER_COLOUR}\])\n├──"
		fi

		# Time
		PS1="$PS1(\[${LIGHTBLUE}\]$(date +%I:%M:%S•%p)\[${USER_COLOUR}\])─"

		# User and hostname
		PS1="$PS1(\[${MAGENTA}\]\u@\h"

		# Current directory
		PS1="$PS1\[${USER_COLOUR}\])─(\[${BROWN}\]\w\[${USER_COLOUR}\])"

		# Git branch
		local BRANCH
		BRANCH=$(git branch 2>/dev/null | sed --quiet 's/\* \(.*\)/ \1/p')
		test -n "$BRANCH" && PS1="$PS1 [\[${BLUE}\]${BRANCH}\[${USER_COLOUR}\]]"

		# Python virtual environment
		test -n "$VIRTUAL_ENV" && PS1="$PS1 [\[${YELLOW}\] venv\[${USER_COLOUR}\]]"

		# Skip to the next line
		PS1="$PS1\r\n\[${USER_COLOUR}\]└─❯\[${NO_COLOUR}\] "

		# Window title
		PS1="$PS1\[\033]0;\u@\h (\w)\007\]"

		# PS2 is used to continue a command using the \ character
		PS2="\[${USER_COLOUR}\]>\[${NO_COLOUR}\] "

		# PS3 is used to enter a number choice in a script
		PS3='Please enter a number from above list: '

		# PS4 is used for tracing a script in debug mode
		PS4="\[${USER_COLOUR}\]+\[${NO_COLOUR}\] "
	}
	PROMPT_COMMAND='__setprompt' # Will run function every time a command is entered

	if cmd_check yazi; then
		__cmd_checker__ yazi-cd
		yazi-cd() {
			local tmp
			tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
			yazi --cwd-file="$tmp"
			if [ -f "$tmp" ]; then
				local dir
				dir="$(cat "$tmp")"
				rm --force "$tmp" > /dev/null
				if [ "$dir" ] && [ "$dir" != "$(pwd)" ]; then
					cd "$dir" || true
				fi
			fi
		}
		bind '"\C-o":"\C-wyazi-cd\C-m"'
	fi

	# Preprinting before shell prompt
	if cmd_check fastfetch; then
		fastfetch
	fi
fi
