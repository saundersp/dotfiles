#!/bin/sh

set -e

USAGE="Kernel/Local packages update helper\nImplemented by @saundersp\n
Usage: $0 FLAG
Available flags:
	m, mod, -m, --mod			Show the options that can be modularized.
	M, make, -M, --make			Transfer arguments to Makefile in the current selected kernel, open the current kernel setup menu by default.
	f, fill, -f, --fill			Show the options that are not enabled. /!\ Intended for the MAXIMUM profile.
	e, empty, -e, --empty			Show the options that are enabled/modularized.
	c, compare, -c, --compare		Compare the current profile with the saved one.
	u, update, -u, --update			Update the kernel.
	p, packages, -p, --packages		Update the localy installed packages.
	ck, change-kernel, -ck, --change-kernel	Change the current selected kernel to specified one.
	s, sign, -s, --sign			Sign the specified module path
	h, help, -h, --help			Which display this help message."

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
		make -j"$NPROC" \
			&& make modules_install -j"$NPROC" \
			&& make install && genkernel --luks initramfs \
			&& grub-mkconfig -o /boot/grub/grub.cfg \
			&& emerge -q @module-rebuild
		cd
	;;
	p|packages|-p|--packages)
		__updatepackages__(){
			for PACKAGE_NAME in $1; do
				if [ ! -d /usr/local/src/"$PACKAGE_NAME" ]; then
					echo "Package $PACKAGE_NAME not installed, skipping..."
					continue
				fi
				cd "$PACKAGE_NAME"
				if [ "$(git pull)" = 'Already up to date.' ]; then
					echo "Package $PACKAGE_NAME already up to date"
				else
					echo "Updating package $PACKAGE_NAME"
					$2
				fi
				cd ..
			done
		}

		cd /usr/local/src

		# https://github.com/arduino/arduino-cli.git
		# Dependencies : dev-lang/go
		# https://github.com/charmbracelet/glow.git
		# Dependencies : dev-lang/go
		# https://github.com/jesseduffield/lazydocker.git
		# Dependencies : dev-lang/go app-containers/docker
		# https://github.com/jesseduffield/lazygit.git
		# Dependencies : dev-lang/go dev-vcs/git
		__updatepackages__ 'arduino-cli glow lazydocker lazygit' 'go install'
		# https://git.suckless.org/dmenu
		# Dependencies : media-libs/fontconfig x11-libs/libX11 x11-libs/libXft x11-libs/libXinerama x11-base/xorg-proto virtual/pkgconfig
		# https://git.suckless.org/st
		# Dependencies : sys-libs/ncurses media-libs/fontconfig x11-libs/libX11 x11-libs/libXft x11-terms/st-terminfo x11-base/xorg-proto virtual/pkgconfig
		__updatepackages__ 'dmenu st' 'make clean install'
		# https://github.com/b3nj5m1n/xdg-ninja.git
		# Dependencies : app-shells/bash
		__updatepackages__ 'xdg-ninja' 'ln -sf /usr/local/src/xdg-ninja/xdg-ninja.sh  /usr/local/bin/xdg-ninja'
		# https://github.com/ankitects/anki.git
		# Dependencies : dev-util/bazel dev-python/PyQt5 dev-python/PyQtWebEngine dev-python/httplib2 dev-python/beautifulsoup4 dev-python/decorator dev-python/jsonschema dev-python/markdown dev-python/requests dev-python/send2trash dev-python/nose dev-python/mock
		__update_anki(){
			./tools/bundle && cd .bazel/out/dist && tar xf anki*qt6.* && cd anki*qt6
			./install.sh &&	cd .. && rm -r * && cd ../../.. && bazel shutdown
		}
		__updatepackages__ 'anki' '__update_anki'
		# https://github.com/espanso/espanso.git
		# Dependencies : cargo-make x11-libs/wxGTK:3.0-gtk3
		__update_espanso(){
			cargo make --profile release build-binary && mv -f target/release/espanso /usr/local/bin/espanso
		}
		__updatepackages__ 'espanso' '__update_espanso'
		# https://github.com/logisim-evolution/logisim-evolution.git
		# Dependencies : dev-java/openjdk
		__update_gradle_app__(){
			APP_NAME=$(pwd | cut -d / -f 5)
			./gradlew clean && ./gradlew shadowJar
			VERSION=$(grep 'version =' gradle.properties | cut -d = -f 2 | sed s/' '//)
			printf '#!/bin/sh\njava -jar %s/build/libs/%s-%s-all.jar' "$(pwd)" "$APP_NAME" "$VERSION" > /usr/local/bin/"$APP_NAME"
			chmod +x /usr/local/bin/"$APP_NAME"
		}
		__updatepackages__ 'logisim-evolution' '__update_gradle_app__'

		cd ~
		GO_BIN_PATH="${GOPATH:-$HOME/go}/bin"
		test "$(ls -A "$GO_BIN_PATH")" && mv -f "$GO_BIN_PATH"/* /usr/local/bin/
		exit 0
	;;
	ck|change-kernel|-ck|--change-kernel)
		if [ -z "$2" ]; then
			echo "You have to specify a kernel index !"
			exit 1
		fi
		TMP_FILE="$(mktemp)"
		mv /usr/src/linux/.config "$TMP_FILE"
		eselect kernel set "$2"
		mv "$TMP_FILE" /usr/src/linux/.config
		cd /usr/src/linux
		make oldconfig
		cd
	;;
	M|make|-M|--make)
		cd /usr/src/linux
		if [ -n "$2" ]; then
			make $2
		else
			make menuconfig
		fi
		cd
	;;
	s|sign|-s|--sign)
		if [ -z "$2" ]; then
			echo "You have to specify at least one relative module path !"
			exit 1
		elif [ "$2" = 'all' ]; then
			./updater.sh s video/nvidia video/nvidia-drm video/nvidia-modeset video/nvidia-peermem video/nvidia-uvm
			./updater.sh s misc/vboxdrv misc/vboxnetadp misc/vboxnetflt
			exit 0
		fi
		NAME=$(grep 'CONFIG_LOCALVERSION'=\" /usr/src/linux/.config | cut -d \" -f 2)
		VERSION=$(grep 'Kernel Configuration' /usr/src/linux/.config | cut -d ' ' -f 3)
		while [ -n "$2" ]; do
			if [ -f /lib/modules/"$VERSION$NAME"/"$2".ko ]; then
				echo "Signing $2 ..."
				/usr/src/linux/scripts/sign-file sha512 /usr/src/linux/certs/signing_key.pem /usr/src/linux/certs/signing_key.x509 /lib/modules/"$VERSION$NAME"/"$2".ko
			else
				echo "Module $2 not found in $VERSION$NAME"
			fi
			shift
		done
	;;
	h|help|-h|--help) echo "$USAGE" ;;
	*) echo "$USAGE" && exit 1 ;;
esac
