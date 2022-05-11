#/usr/bin/env bash

__apply_patch__(){
	if [ $EUID -ne 0 ]; then
		echo Root priviliges required !
		exit 1
	fi
	local dmenu_path=/usr/local/src/dmenu
	local patches_dir=$(pwd)
	if [ "$1" = 'clean' ]; then
		cd $dmenu_path
		make uninstall
		make clean
		rm *.orig *.rej

		cd -
		patch -p1 -R -d $dmenu_path < ./dmenu-patches.diff

		cd $dmenu_path
		rm *.orig *.rej config.h
		git checkout *
		cd -
		exit 0
	fi

	patch -p1 -d $dmenu_path < ./dmenu-patches.diff
	cd $dmenu_path
	make install
	cd -
}
__apply_patch__ $*
unset __apply_patch__
