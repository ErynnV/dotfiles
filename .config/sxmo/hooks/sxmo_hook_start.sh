#!/bin/sh
# configversion: 5d777b987cebc4d4b4ceba5734f22fd8
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Runs upon system start and starts various background services

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# Create xdg user directories, such as ~/Pictures
xdg-user-dirs-update

# Not dangerous if "locker" isn't an available state
sxmo_state.sh set locker

if [ -n "$SXMO_ROTATE_START" ]; then
	sxmo_rotate.sh
fi

# Load our sound daemons

if [ -z "$SXMO_NO_AUDIO" ]; then
	if ! [ -d /run/systemd/system ]; then
		if [ "$(command -v pulseaudio)" ]; then
			sxmo_service.sh start pulseaudio
		elif [ "$(command -v pipewire)" ]; then
			# pipewire-pulse will start pipewire
			sxmo_service.sh start pipewire-pulse
			sxmo_service.sh start wireplumber
		fi
	fi

	# monitor for headphone for statusbar
	sxmo_service.sh start sxmo_soundmonitor
fi

# Periodically update some status bar components
sxmo_hook_statusbar.sh all
sxmo_jobs.sh start statusbar_periodics sxmo_run_aligned.sh 60 \
	sxmo_hook_statusbar.sh periodics

# dunst is required for warnings.
sxmo_service.sh start dunst

# start adaptive brightness at boot
# sxmo_service.sh start sxmo_adaptivebrightness

# load some other little things here too.
case "$SXMO_WM" in
	river)
		sxmo_service.sh start sxmo_wob
		sxmo_service.sh start bonsaid.sxmo
		sxmo_service.sh start sxmo_riverbar
		;;
	sway)
		sxmo_service.sh start sxmo_wob
		sxmo_service.sh start sxmo_menumode_toggler
		sxmo_service.sh start bonsaid.sxmo
		;;
	dwm|i3)
		sxmo_service.sh start sxmo_xob

		# Auto hide cursor with touchscreen, Show it with a mouse
		if command -v "unclutter-xfixes" > /dev/null; then
			set -- unclutter-xfixes
		else
			set -- unclutter
		fi
		sxmo_service.sh start "$1"

		sxmo_service.sh start autocutsel
		sxmo_service.sh start autocutsel-primary
		sxmo_service.sh start sxmo-x11-status
		sxmo_service.sh start bonsaid.sxmo
		[ -n "$SXMO_MONITOR" ] && xrandr --output "$SXMO_MONITOR" --primary
		# Set onboard to auto-hide in config first
		if [ "$SXMO_KEYBOARD" = "onboard" ]; then
			onboard "$SXMO_KEYBOARD_ARGS"
		fi
		case "$SXMO_WM" in
			i3)
				xbindkeys -f "$XDG_CONFIG_HOME/sxmo/xbindkeysrc_$SXMO_BINDING_PROVIDER"
				;;
		esac
		;;
esac

sxmo_service.sh start start pimsync

# Turn on auto-suspend
if sxmo_wakelock.sh isenabled; then
	sxmo_wakelock.sh lock sxmo_not_suspendable infinite
	sxmo_service.sh start sxmo_autosuspend
fi

# To setup initial unlock state
sxmo_state.sh set unlock

# Turn on lisgd
if [ ! -e "$XDG_CACHE_HOME"/sxmo/sxmo.nogesture ]; then
	sxmo_service.sh start sxmo_hook_lisgd
fi

if command -v ModemManager > /dev/null; then
	# Turn on the dbus-monitors for modem-related tasks
	sxmo_service.sh start sxmo_modemmonitor

	# place a wakelock for 120s to allow the modem to fully warm up (eg25 +
	# elogind/systemd would do this for us, but we don't use those.)
	sxmo_wakelock.sh lock sxmo_modem_warming_up 120s
fi

# Start the desktop wallpaper
sxmo_service.sh start sxmo_bg

# Start the output manager
sxmo_service.sh start kanshi

# Start the desktop widget (e.g. clock)
sxmo_service.sh start sxmo_conky

# Monitor the battery
sxmo_service.sh start sxmo_battery_monitor

# It watch network changes and update the status bar icon by example
sxmo_service.sh start sxmo_networkmonitor

# The daemon that display notifications popup messages
sxmo_service.sh start sxmo_notificationmonitor

# Play a funky startup tune if you want (disabled by default)
#mpv --quiet --no-video ~/welcome.ogg &

gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# mmsd and vvmd
if command -v mmsdtng > /dev/null; then
	if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then
		sxmo_service.sh start mmsd-tng
	fi
fi

if command -v vvmd > /dev/null; then
	if [ -f "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" ]; then
		sxmo_service.sh start vvmd
	fi
fi

# add some warnings if things are not setup correctly
if ! command -v "sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh";  then
	sxmo_notify_user.sh --urgency=critical \
		"No deviceprofile found $SXMO_DEVICE_NAME. See: https://sxmo.org/deviceprofile"
fi

sxmo_migrate.sh state || sxmo_notify_user.sh --urgency=critical \
	"Config needs migration" "$? file(s) in your sxmo configuration are out of date and disabled - using defaults until you migrate (run sxmo_migrate.sh)"
