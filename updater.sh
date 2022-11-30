#/bin/sh

set -e

USAGE="Kernel/Local packages update helper\nImplemented by @saundersp\n\nDocumentation:\n
\t$0 m, mod, -m, --mod
\tShow the options that can be modularized.

\t$0 M, make, -M, --make
\tTransfer arguments to Makefile in the current selected kernel, open the current kernel setup menu by default.

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

\t$0 ck, change-kernel, -ck, --change-kernel
\tChange the current selected kernel to specified one.

\t$0 s, sign, -s, --sign
\tSign the specified module path

\t$0 h, help, -h, --help
\tWhich display this help message."

CURRENT=DEFAULT.config
#CURRENT=MAXIMUM.config

case "$1" in
	m|mod|-m|--mod) rg "=y" /usr/src/linux/.config | sed "s/=y/=m/" | xargs -I{} rg "{}" MAXIMUM.config | less ;;
	f|fill|-f|--fill) rg 'is not set' /usr/src/linux/.config | sed 's/# CONFIG_//;s/ is not set//' | less ;;
	e|empty|-e|--empty) rg '=y|=m' /usr/src/linux/.config | sed 's/CONFIG_//' | less ;;
	c|compare|-c|--compare) nvim -d /usr/src/linux/.config $CURRENT ;;
	u|update|-u|--update)
		cd /usr/src/linux
		NPROC=$(nproc)
		make -j$NPROC \
			&& make modules_install -j$NPROC \
			&& make install && genkernel --luks initramfs \
			&& grub-mkconfig -o /boot/grub/grub.cfg \
			&& emerge -q @module-rebuild
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
		__updatepackages__ 'xdg-ninja' 'ln -sf /usr/local/src/xdg-ninja/xdg-ninja.sh  /usr/local/bin/xdg-ninja'
		__update_anki(){
			./tools/bundle && cd .bazel/out/dist && tar xf anki*qt6.* && cd anki*qt6
			./install.sh &&	cd .. && rm -r * && cd ../../.. && bazel shutdown
		}
		__updatepackages__ 'anki' '__update_anki'
		__updatepackages__ 'espanso' 'cargo install --force cargo-make && mv target/release/espanso /usr/local/bin/espanso'

		cd ~
		test "$(ls -A go/bin)" != "" && mv go/bin/* /usr/local/bin/
		exit 0
	;;
	ck|change-kernel|-ck|--change-kernel)
		if [ -z "$2" ]; then
			echo "You have to specify a kernel index !"
			exit 1
		fi
		mv /usr/src/linux/.config /tmp/kernel.__tmp__
		eselect kernel set $2
		mv /tmp/kernel.__tmp__ /usr/src/linux/.config
		cd /usr/src/linux
		make oldconfig
		cd
	;;
	M|make|-M|--make)
		cd /usr/src/linux
		if [ ! -z "$2" ]; then
			make $2
		else
			make menuconfig
		fi
		cd
	;;
	# Mandatory to use NVIDIA and VirtualBox modules
	# misc/vboxdrv misc/vboxnetadp miisc/vboxnetflt
	# video/nvidia video/nvidia-uvm video/nvidia-modeset
	s|sign|-s|--sign)
		if [ -z "$2" ]; then
			echo "You have to specify at least one relative module path !"
			exit 1
		elif [ "$2" = 'all' ]; then
			exec ./updater.sh s video/nvidia video/nvidia-uvm video/nvidia-modeset misc/vboxdrv misc/vboxnetadp misc/vboxnetflt
		fi
		NAME=$(grep CONFIG_LOCALVERSION=\" /usr/src/linux/.config | cut -d \" -f 2)
		VERSION=$(grep 'Kernel Configuration' /usr/src/linux/.config | cut -d ' ' -f 3)
		while [ ! -z "$2" ]; do
			echo Signing $2 ...
			/usr/src/linux/scripts/sign-file sha256 /usr/src/linux/certs/signing_key.pem /usr/src/linux/certs/signing_key.x509 /lib/modules/$VERSION$NAME/$2.ko
			shift
		done
	;;
	h|help|-h|--help) echo -e "$USAGE" && exit 0 ;;
	*) echo -e "$USAGE" && exit 1 ;;
esac
