#/bin/sh

set -e

USAGE="Kernel/Local packages update helper\nImplemented by @saundersp\n\nDocumentation:\n
\t$0 m, mod, -m, --mod
\tShow the options that can be modularized.

\t$0 f, fill, -f, --fill
\tShow the options that are not enabled.
\t/!\ Intended for the MAXIMUM profile.

\t$0 e, empty, -e, --empty
\tShow the options that are enabled/modularized.

\t$0 c, compare, -c, --compare
\tCompare the current profile with the saved one.

\t$0 u, update, -u, --update
\tUpdate the kernel.

\t$0 p, packages, -p, --packages
\tUpdate the localy installed packages.

\t$0 h, help, -h, --help
\tWhich display this help message."

CURRENT=LAPTOP.config

case "$1" in
	m|mod|-m|--mod) rg "=y" /usr/src/linux/.config | sed "s/=y/=m/" | xargs -I{} rg "{}" MAXIMUM.config | less ;;
	f|fill|-f|--fill) rg 'is not set' /usr/src/linux/.config | sed 's/# CONFIG_//;s/ is not set//' | less ;;
	e|empty|-e|--empty) rg '=y|=m' /usr/src/linux/.config | sed 's/CONFIG_//' | less ;;
	c|compare|-c|--compare) nvim -d /usr/src/linux/.config $CURRENT ;;
	u|update|-u|--update)
		cd /usr/src/linux
		local NPROC=$(nproc)
		make -j$NPROC \
			&& make modules_install -j$NPROC \
			&& make install && genkernel --luks initramfs \
			&& grub-mkconfig -o /boot/grub/grub.cfg \
			&& emerge -q nvidia-drivers 
		cd
	;;
	p|packages|-p|--packages)
		__updatepackages__(){
			for PACKAGE_NAME in $1; do
				if [ ! -d /usr/local/src/$PACKAGE_NAME ]; then
					echo Package $PACKAGE_NAME not installed, skipping...
					continue
				fi
				cd $PACKAGE_NAME
				if [[ $(git pull) == 'Already up to date.' ]]; then
					echo Package $PACKAGE_NAME already up to date
				else
					$2
				fi
				cd ..
			done
		}

		cd /usr/local/src

		__updatepackages__ 'arduino-cli glow lazydocker lazygit' 'go install'
		__updatepackages__ 'dmenu st' 'make clean install'
		__updatepackages__ 'xdg-ninja' 'ln -sf /usr/local/src/xdg-ninja/xdg-ninja.sh  /usr/bin/xdg-ninja'
		__updatepackages__ 'grub-holdshift' 'ln -sf /usr/local/src/grub-holdshift/31_hold_shift /etc/grub.d/'

		cd ~
		if [ -d go ]; then
			mv go/bin/* /usr/bin/
			#rm -r go
		fi
	;;
	h|help|-h|--help) echo -e "$USAGE" && exit 0 ;;
	*) echo -e "$USAGE" && exit 1 ;;
esac