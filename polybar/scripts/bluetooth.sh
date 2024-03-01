#!/bin/sh

bluetooth_print() {
	if bluetoothctl show | grep -q 'Powered: yes'; then
		# nf-md-bluetooth
		printf '󰂯'

		devices_paired=$(bluetoothctl devices | grep Device | cut -d ' ' -f 2)
		counter=0

		for device in $devices_paired; do
			device_info=$(bluetoothctl info "$device")

			if echo "$device_info" | grep -q 'Connected: yes'; then
				device_alias=$(echo "$device_info" | awk '/Alias/ { print $2 }')
				device_power=$(echo "$device_info" | grep -Po 'Battery Percentage: 0x\w{0,2} \(\K\d{1,3}')

				if [ $counter -gt 0 ]; then
					printf ' \-'
				fi

				if [ -z "$device_power" ]; then
					# nf-md-battery_alert
					printf ' %s 󰂃' "$device_alias"
				else
					# nf-md-battery_bluetooth_variant
					printf ' %s 󰥉 %s%%' "$device_alias" "$device_power"
				fi

				counter=$((counter + 1))
			fi
		done

		printf '\n'
	else
		# nf-md-bluetooth_off
		echo '%{F#444}󰂲'
	fi
}

bluetooth_toggle() {
	if bluetoothctl show | grep -q 'Powered: no'; then
		bluetoothctl power on >> /dev/null
		sleep 1

		devices_paired=$(bluetoothctl devices | grep Device | cut -d ' ' -f 2)
		echo "$devices_paired" | while read -r line; do
			bluetoothctl connect "$line" >> /dev/null
		done
	else
		devices_paired=$(bluetoothctl devices | grep Device | cut -d ' ' -f 2)
		echo "$devices_paired" | while read -r line; do
			bluetoothctl disconnect "$line" >> /dev/null
		done

		bluetoothctl power off >> /dev/null
	fi
}

if command -v bluetoothctl >> /dev/null; then
	case "$1" in
		--toggle)
			bluetooth_toggle
			;;
		*)
			bluetooth_print
			;;
	esac
fi
