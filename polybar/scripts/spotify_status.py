#!/usr/bin/env python

import dbus

def main():
	# nf-md-play, nf-md-pause
	play_pause = ['󰐊', '󰏤']

	session_bus = dbus.SessionBus()
	try:
		spotify_bus = session_bus.get_object('org.mpris.MediaPlayer2.spotify', '/org/mpris/MediaPlayer2')
	except Exception as e: # Unknown owner ...
		if isinstance(e, dbus.exceptions.DBusException):
			print('')
		else:
			print(e)
		return
	spotify_properties = dbus.Interface(spotify_bus, 'org.freedesktop.DBus.Properties')
	metadata = spotify_properties.Get('org.mpris.MediaPlayer2.Player', 'Metadata')
	status = spotify_properties.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus')

	# Handle play/pause label
	if status == 'Playing':
		play_pause = play_pause[0]
	elif status == 'Paused':
		play_pause = play_pause[1]
	else: # Unknown status
		play_pause = status

	artist = metadata['xesam:artist'][0] if metadata['xesam:artist'] else ''
	song = metadata['xesam:title'] if metadata['xesam:title'] else ''

	print('' if not artist or not song else f'{play_pause} {artist}: {song}')

if __name__ == '__main__':
	main()

