#!/bin/sh

# Debug changes to repository
# git am patch_file.diff
# Update the patch file (LENGTH = dmenu:7 st:10)
# git format-patch --stdout HEAD~$LENGTH > patch_file.diff

__apply_patch__(){
	if [ "$(id -u)" -ne 0 ]; then
		echo Root priviliges required !
		exit 1
	fi
	if [ -z "$1" ]; then
		echo You have to enter a program name to patch !
		exit 1
	fi
	prog=$1
	shift

	prog_path=/usr/local/src/$prog

	if [ ! -f ./"$prog"-patches.diff ]; then
		echo Missing patch file !
		exit 1
	fi

	if [ "$1" = 'clean' ]; then
		cd "$prog_path"
		make uninstall
		make clean
		rm *.orig *.rej

		cd -
		patch -p1 -R -t -d "$prog_path" < ./"$prog"-patches.diff

		cd "$prog_path"
		rm *.orig *.rej config.h
		git checkout *
		cd -
		exit 0
	fi

	patch -p1 -d "$prog_path" < ./"$prog"-patches.diff
	cd "$prog_path"
	make install
	cd -
}
__apply_patch__ "$@"
unset __apply_patch__
