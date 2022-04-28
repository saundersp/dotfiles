#!/usr/bin/env bash

print_formatted_fs(){
	local i=1
	local placeholder=' %name% %used%'
	local sep=:
	for option in $*; do

		if [ $i -eq 0 ]; then
			placeholder=$option
		else
			local dev_name=$(echo "$option" | cut -d $sep -f 1)
			local name=$(echo "$option" | cut -d $sep -f 2)
			local used=$(df $dev_name | sed 1d |  awk '{print $5}')
			local tempholder=$(echo "$placeholder" | sed "s$sep%name%$sep$name${sep}g;s$sep%used%$sep$used${sep}g")
			if [ $i -gt 1 ]; then
				printf ' - %s' "$tempholder"
			else
				printf ' %s' "$tempholder"
			fi
		fi

		i=$((i+1))
	done
	printf '\n'
}

print_formatted_fs $*

