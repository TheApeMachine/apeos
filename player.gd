extends Node

onready var client = $client

func _ready():
	client.connect("share_joined", self, "_share_joined")
	client.connect("share_sealed", self, "_share_sealed")
	client.connect("connected", self, "_connected")
	client.connect("disconnected", self, "_disconnected")
	client.rtc_mp.connect("peer_connected", self, "_mp_peer_connected")
	client.rtc_mp.connect("peer_disconnected", self, "_mp_peer_disconnected")
	client.rtc_mp.connect("server_disconnected", self, "_mp_server_disconnect")
	client.rtc_mp.connect("connection_succeeded", self, "_mp_connected")

func _process(delta):
	client.rtc_mp.poll()
	while client.rtc_mp.get_available_packet_count() > 0:
		_log(client.rtc_mp.get_packet().get_string_from_utf8())

func _connected(id):
	_log("Signaling server connected with ID: %d" % id)

func _disconnected():
	_log("Signaling server disconnected: %d - %s" % [client.code, client.reason])

func _share_joined(share):
	_log("Joined share %s" % share)

func _share_sealed():
	_log("Share has been sealed")

func _mp_connected():
	_log("Multiplayer is connected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_server_disconnect():
	_log("Multiplayer is disconnected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_peer_connected(id : int):
	_log("Multiplayer peer %d connected" % id)

func _mp_peer_disconnected(id : int):
	_log("Multiplayer peer %d disconnected" % id)

func _log(msg):
	print(msg)

func ping():
	_log(client.rtc_mp.put_packet("ping".to_utf8()))

func _on_Peers_pressed():
	var d = client.rtc_mp.get_peers()
	_log(d)
	for k in d:
		_log(client.rtc_mp.get_peer(k))

func start():
	client.start("localhost:1235")

func _on_Seal_pressed():
	client.seal_share()

func stop():
	client.stop()
