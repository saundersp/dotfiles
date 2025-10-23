#!/bin/sh

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
command -v less >> /dev/null && export LESSHISTFILE="$XDG_STATE_HOME"/less_history
command -v gradle >> /dev/null && export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
command -v java >> /dev/null && export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
command -v python >> /dev/null && export PYTHONHISTORY="$XDG_DATA_HOME"/python_history
command -v ipython >> /dev/null && export IPYTHONDIR="$XDG_CONFIG_HOME"/ipython
command -v go >> /dev/null && export GOPATH="$XDG_DATA_HOME"/go
if command -v docker >> /dev/null; then
	export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
	if [ -f /usr/libexec/docker/cli-plugins/docker-compose ] || [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
		export COMPOSE_BAKE=true
	fi
fi
command -v cargo >> /dev/null && export CARGO_HOME="$XDG_DATA_HOME"/cargo
command -v npm >> /dev/null && export NPM_CONFIG_CACHE="$XDG_CACHE_HOME"/npm
command -v wget >> /dev/null && alias wget='wget --hsts-file=$XDG_DATA_HOME/wget-hsts'

if test -f "$HOME"/.bashrc; then
	. "$HOME"/.bashrc
fi

if [ "$(tty)" = /dev/tty1 ]; then
	if command -v tmux >> /dev/null; then
		tmux
	fi
fi
