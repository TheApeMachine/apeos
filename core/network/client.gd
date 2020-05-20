extends Node

class_name Client

var mclient = MultiplayerClient.new()

func _ready():
	mclient.connect("lobby_joined", self, "_lobby_joined")
	mclient.connect("lobby_sealed", self, "_lobby_sealed")
	mclient.connect("connected", self, "_connected")
	mclient.connect("disconnected", self, "_disconnected")
	mclient.rtc_mp.connect("peer_connected", self, "_mp_peer_connected")
	mclient.rtc_mp.connect("peer_disconnected", self, "_mp_peer_disconnected")
	mclient.rtc_mp.connect("server_disconnected", self, "_mp_server_disconnect")
	mclient.rtc_mp.connect("connection_succeeded", self, "_mp_connected")

func poll() -> String:
	mclient.rtc_mp.poll()
	
	while mclient.rtc_mp.get_available_packet_count() > 0:
		return mclient.rtc_mp.get_packet().get_string_from_utf8()
