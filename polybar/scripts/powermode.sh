#!/bin/sh

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
	case "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" in
		# Run the CPU at the maximum frequency, obtained from
		# /sys/devices/system/cpu/cpuX/cpufreq/scaling_max_freq
		performance) printf  ;; # nf-fa-bolt
		# Run the CPU at the minimum frequency, obtained from
		# /sys/devices/system/cpu/cpuX/cpufreq/scaling_min_freq
		powersave) printf  ;; # nf-fa-leaf
		# Run the CPU at user specified frequencies, configurable via
		# /sys/devices/system/cpu/cpuX/cpufreq/scaling_setspeed
		userspace) printf 󱍰 ;; # nf-md-account_cog
		# Scales the frequency dynamically according to current load.
		# Jumps to the highest frequency and then possibly back off as the idle time increases.
		ondemand) printf  ;; # nf-fa-angles_up
		# Scales the frequency dynamically according to current load.
		# Scales the frequency more gradually than ondemand
		conservative) printf  ;; # nf-fa-angle_up
		# Scheduler-driven CPU frequency selection
		schedutil) printf 󱁻 ;; # nf-md-file_cog
		# Unknown
		*) printf  ;;
	esac
fi
