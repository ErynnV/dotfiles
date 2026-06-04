local msg = require 'mp.msg'

local settings = {
	reverse_key_binding = "Ctrl+e",
}

function reverse_playlist()
	msg.debug("reverse_playlist")
	local playlist_count = mp.get_property_number("playlist/count")
	for i = 0,playlist_count,1
	do
		mp.commandv("playlist-move", 0, playlist_count-i)
	end
	mp.osd_message("Playlist reversed", 1)
end

mp.add_key_binding(settings.reverse_key_binding, "reverse_playlist", reverse_playlist)
