#/usr/bin/env bash

__apply_patch__(){
	if [ $EUID -ne 0 ]; then
		echo Root priviliges required !
		exit 1
	fi
	local st_path=/usr/local/src/st
	local patches_dir=$(pwd)
	if [ "$1" = 'clean' ]; then
		cd $st_path
		make uninstall
		make clean
		rm *.orig *.rej

		cd -
		patch -p1 -t -d $st_path < ./st-xresources-signal-reloading-20220407-ef05519.diff
		patch -p0 -t -d $st_path < ./st-mousescroll.diff
		patch -p1 -t -d $st_path < ./st-visualbell2-basic-2020-05-13-045a0fa.diff
		patch -p0 -t -d $st_path < ./st-delkey-20201112-4ef0cbd.diff
		patch -p1 -t -d $st_path < ./st-scrollback-0.8.5.diff
		patch -p1 -t -d $st_path < ./st-ligatures-boxdraw-20210824-0.8.4.diff
		patch -p1 -t -d $st_path < ./st-boxdraw_v2-0.8.5.diff
		patch -p1 -t -d $st_path < ./st-hasklug-font.diff

		cd $st_path
		rm *.orig *.rej config.h
		git checkout *
		cd -
		exit 0
	fi

	patch -p1 -d $st_path < ./st-hasklug-font.diff
	patch -p1 -d $st_path < ./st-boxdraw_v2-0.8.5.diff
	patch -p1 -d $st_path < ./st-ligatures-boxdraw-20210824-0.8.4.diff
	patch -p1 -d $st_path < ./st-scrollback-0.8.5.diff
	patch -p0 -d $st_path < ./st-delkey-20201112-4ef0cbd.diff
	patch -p1 -d $st_path < ./st-visualbell2-basic-2020-05-13-045a0fa.diff
	patch -p0 -d $st_path < ./st-mousescroll.diff
	patch -p1 -d $st_path < ./st-xresources-signal-reloading-20220407-ef05519.diff
	cd $st_path
	make install
	cd -
}
__apply_patch__ $*
unset __apply_patch__
