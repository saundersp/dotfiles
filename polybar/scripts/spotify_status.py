#!/usr/bin/env python

import dbus
from typing import Final

# nf-md-play, nf-md-pause
play_pause: Final[list[str]] = ['󰐊', '󰏤']

def main() -> None:
	session_bus: Final[dbus.SessionBus] = dbus.SessionBus()
	try:
		spotify_bus: Final[dbus.ObjectPath.ProxyObjectClass] = session_bus.get_object('org.mpris.MediaPlayer2.spotify', '/org/mpris/MediaPlayer2')
	except Exception as e:  # Unknown owner ...
		if not isinstance(e, dbus.exceptions.DBusException):
			print(e)
		return
	spotify_properties: Final[dbus.Interface] = dbus.Interface(spotify_bus, 'org.freedesktop.DBus.Properties')
	metadata: Final[dict[str, str]] = spotify_properties.Get('org.mpris.MediaPlayer2.Player', 'Metadata')
	status: Final[str] = spotify_properties.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus')

	play_label: str = status  # Unknown status
	# Handle play/pause label
	if status == 'Playing':
		play_label = play_pause[0]
	elif status == 'Paused':
		play_label = play_pause[1]

	artist: Final[str] = metadata['xesam:artist'][0] if metadata['xesam:artist'] else ''
	song: Final[str] = metadata['xesam:title'] if metadata['xesam:title'] else ''

	print('' if not artist or not song else f'{play_label} {artist}: {song}')

if __name__ == '__main__':
	main()
