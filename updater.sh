#!/bin/sh

set -e

USAGE="Kernel/Local packages update helper\nImplemented by @saundersp

Usage: $0 FLAG
Available flags:
	m, mod, -m, --mod			Show the options that can be modularized.
	M, make, -M, --make			Transfer arguments to Makefile in the current selected kernel, open the current kernel setup menu by default.
	f, fill, -f, --fill			Show the options that are not enabled. /!\ Intended for the MAXIMUM profile.
	e, empty, -e, --empty			Show the options that are enabled/modularized.
	c, compare, -c, --compare		Compare the current profile with the saved one.
	u, update, -u, --update			Update the kernel.
	p, packages, -p, --packages		Update the locally installed packages.
	ck, change-kernel, -ck, --change-kernel	Change the current selected kernel to specified one.
	s, sign, -s, --sign			Sign the specified module path
	h, help, -h, --help			Which display this help message."

case "$1" in
	m|mod|-m|--mod) rg "=y" /usr/src/linux/.config | rg -v '_HAVE_' | sed 's/CONFIG_//;s/=y//' | less ;;
	f|fill|-f|--fill) rg 'is not set' /usr/src/linux/.config | sed 's/# CONFIG_//;s/ is not set//' | less ;;
	e|empty|-e|--empty) rg '=y|=m' /usr/src/linux/.config | rg -v '_HAVE_' | sed 's/CONFIG_//' | less ;;
	c|compare|-c|--compare) nvim -d /usr/src/linux/.config DEFAULT.config ;;
	u|update|-u|--update)
		cd /usr/src/linux
		NPROC=$(nproc)
		make modules_prepare
		if command -v distcc >> /dev/null; then
			DISTCC_PROC=$(distcc-config --get-hosts | grep -Po '/(\d)' | sed 's./..' | paste -sd + | bc)
			if ! distcc-config --get-hosts | grep -Pq 'localhost/\d'; then
				DISTCC_PROC=$((DISTCC_PROC + NPROC))
			fi
			make CXX=distcc CC=distcc -j"$DISTCC_PROC" -l"$NPROC"
			make modules_install -j"$NPROC"
			make install
			genkernel --kernel-cc=distcc --utils-cc=distcc --utils-cxx=distcc --luks initramfs
		else
			make -j"$NPROC" -l"$NPROC"
			make modules_install -j"$NPROC"
			make install
			genkernel --luks initramfs
		fi
		grub-mkconfig -o /boot/grub/grub.cfg
		emerge -v @module-rebuild
	;;
	p|packages|-p|--packages)
		__updatepackages__(){
			__r__(){
				end="$1"
				for _ in $(seq 1 "$end") ; do
					env printf '%s' "$2";
				done
			}
			for PACKAGE_NAME in $1; do
				if [ ! -d /usr/local/src/"$PACKAGE_NAME" ]; then
					#echo "Package $PACKAGE_NAME not installed, skipping..."
					continue
				fi
				cd "$PACKAGE_NAME" || continue
				env printf "┌$(__r__ 40 ─)┐\n"
				env printf "│ %-38s │\n" "$PACKAGE_NAME"
				env printf "└$(__r__ 40 '─')┘\n"
				if [ "$(git pull)" = 'Already up to date.' ]; then
					echo 'Already up to date'
				else
					$2
				fi
				cd ..
			done
			unset __r__
		}

		OLD_PWD="$(pwd)"
		cd /usr/local/src || exit 1

		# https://github.com/arduino/arduino-cli.git
		# Dependencies : dev-lang/go
		# https://github.com/charmbracelet/glow.git
		# Dependencies : dev-lang/go
		# https://github.com/jesseduffield/lazydocker.git
		# Dependencies : dev-lang/go app-containers/docker
		# https://github.com/jesseduffield/lazygit.git
		# Dependencies : dev-lang/go dev-vcs/git
		# https://github.com/jesseduffield/lazynpm.git
		# Dependencies : dev-lang/go net-libs/nodejs
		# https://github.com/mrtazz/checkmake.git
		# Dependencies : dev-lang/go app-text/pandoc
		__updatepackages__ 'arduino-cli glow lazydocker lazygit lazynpm checkmake' 'go install'

		# https://git.suckless.org/st
		# Dependencies : sys-libs/ncurses media-libs/fontconfig x11-libs/libX11 x11-libs/libXft x11-terms/st-terminfo x11-base/xorg-proto virtual/pkgconfig
		__update_suckless__(){
			cd --
			PATCH_PATH=$(dirname "$(realpath $0)")/patches
			cd -
			(cd "$PATCH_PATH" && ./patch.sh "$PACKAGE_NAME" clean)
			git pull
			(cd "$PATCH_PATH" && ./patch.sh "$PACKAGE_NAME")
		}
		__updatepackages__ 'st' '__update_suckless__'

		# https://github.com/b3nj5m1n/xdg-ninja.git
		# Dependencies : app-shells/bash app-misc/jq
		# Optional dependencies : app-misc/glow
		__updatepackages__ 'xdg-ninja' 'ln -svf /usr/local/src/xdg-ninja/xdg-ninja.sh /usr/local/bin/xdg-ninja'

		# https://github.com/espanso/espanso.git
		# Dependencies : dev-lang/rust x11-libs/wxGTK net-fs/samba
		# https://github.com/veeso/termscp.git
		# Dependencies : dev-lang/rust dev-util/pkgconf dev-libs/openssl
		# https://github.com/typst/typst.git
		# Dependencies : dev-lang/rust
		__update_rust__(){
			cargo build --profile release
			mv -f target/release/"$PACKAGE_NAME" /usr/local/bin/"$PACKAGE_NAME"
			rm -r target
		}
		__updatepackages__ 'espanso termscp typst' '__update_rust__'

		# https://github.com/logisim-evolution/logisim-evolution.git
		# Dependencies : dev-java/openjdk:1.8
		__update_gradle_app__(){
			APP_NAME=$(pwd | cut -d / -f 5)
			./gradlew clean && ./gradlew shadowJar
			VERSION=$(grep 'version =' gradle.properties | cut -d = -f 2 | sed s/' '//)
			printf '#!/bin/sh\njava -jar %s/build/libs/%s-%s-all.jar' "$(pwd)" "$APP_NAME" "$VERSION" > /usr/local/bin/"$APP_NAME"
			chmod +x /usr/local/bin/"$APP_NAME"
		}
		__updatepackages__ 'logisim-evolution' '__update_gradle_app__'

		# https://github.com/neovim/neovim.git
		# Dependencies : dev-build/cmake dev-build/ninja app-arch/unzip net-misc/curl sys-devel/gettext sys-devel/gcc
		__update_cmake__(){
			make CMAKE_BUILD_TYPE=Release -j $(nproc) -l $(nproc) && make install clean && rm -rf build .deps
		}
		__updatepackages__ 'neovim' '__update_cmake__'

		# https://github.com/ventoy/Ventoy
		__updatepackages__ 'Ventoy' 'echo Ventoy updated, Please build then plug USB'

		FONT_DIR=/usr/share/fonts/Hasklig
		if [ -d "$FONT_DIR" ]; then
			LATEST_TAG=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \" -f 4)
			if [ ! -f "$FONT_DIR"/VERSION ] || [ ! "$(cat $FONT_DIR/VERSION)" = "$LATEST_TAG" ]; then
				printf '\nUpdating font Hasklig\n'
				wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/"$LATEST_TAG"/Hasklig.zip
				rm -rf "$FONT_DIR"
				mkdir "$FONT_DIR"
				unzip -q Hasklig.zip -d "$FONT_DIR"
				rm Hasklig.zip
				echo "$LATEST_TAG" > "$FONT_DIR"/VERSION
				printf '\nUpdated font Hasklig\n'
			fi
		fi

		cd "$OLD_PWD"
		GO_BIN_PATH="${GOPATH:-$HOME/go}/bin"
		test -d "$GO_BIN_PATH" && test "$(ls -A "$GO_BIN_PATH")" && mv -f "$GO_BIN_PATH"/* /usr/local/bin/ || exit 0
	;;
	ck|change-kernel|-ck|--change-kernel)
		if [ -z "$2" ]; then
			echo "You have to specify a kernel index !"
			exit 1
		fi
		TMP_FILE="$(mktemp)"
		cp /usr/src/linux/.config "$TMP_FILE"
		eselect kernel set "$2"
		mv "$TMP_FILE" /usr/src/linux/.config
		(cd /usr/src/linux && make oldconfig)
	;;
	M|make|-M|--make)
		cd /usr/src/linux
		if [ -n "$2" ]; then
			make $2
		else
			make menuconfig
		fi
	;;
	s|sign|-s|--sign)
		if [ -z "$2" ]; then
			echo "You have to specify at least one relative module path !"
			exit 1
		elif [ "$2" = 'all' ]; then
			./"$0" s video/nvidia video/nvidia-drm video/nvidia-modeset video/nvidia-peermem video/nvidia-uvm
			./"$0" s misc/vboxdrv misc/vboxnetadp misc/vboxnetflt
			exit 0
		fi
		NAME=$(grep 'CONFIG_LOCALVERSION'=\" /usr/src/linux/.config | cut -d \" -f 2)
		VERSION=$(grep 'Kernel Configuration' /usr/src/linux/.config | cut -d ' ' -f 3)
		while [ -n "$2" ]; do
			if [ -f /lib/modules/"$VERSION$NAME"/"$2".ko ]; then
				echo "Signing $2 ..."
				/usr/src/linux/scripts/sign-file sha3-512 /usr/src/linux/certs/signing_key.pem /usr/src/linux/certs/signing_key.x509 /lib/modules/"$VERSION$NAME"/"$2".ko
			else
				echo "Module $2 not found in $VERSION$NAME"
			fi
			shift
		done
	;;
	h|help|-h|--help) echo "$USAGE" ;;
	*) echo "$USAGE" && exit 1 ;;
esac
