extends Node

export var autojoin = true
export var share = ""

var client: WebSocketClient = WebSocketClient.new()
var code = 1000
var reason = "unknown"

signal share_joined(share)
signal connected(id)
signal disconnected()
signal peer_connected(id)
signal peer_disconnected(id)
signal offer_received(id, offer)
signal answer_received(id, answer)
signal candidate_received(id, mid, index, sdp)
signal share_sealed()

func _init():
	client.connect("data_received", self, "_parse_msg")
	client.connect("connection_established", self, "_connected")
	client.connect("connection_closed", self, "_closed")
	client.connect("connection_error", self, "_closed")
	client.connect("server_close_request", self, "_close_request")

func connect_to_url(url):
	close()
	code = 1000
	reason = "Unknown"
	client.connect_to_url(url)

func close():
	client.disconnect_from_host()

func _closed(was_clean = false):
	emit_signal("disconnected")

func _close_request(code, reason):
	self.code = code
	self.reason = reason

func _connected(protocol = ""):
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

	if autojoin:
		join_share(share)

func _parse_msg():
	var pkt_str : String = client.get_peer(1).get_packet().get_string_from_utf8()
	client.get_peer(1).put_packet(pkt_str.to_utf8())

func join_share(share):
	return client.get_peer(1).put_packet(("join_share %s\n" % share).to_utf8())


func seal_share():
	return client.get_peer(1).put_packet("S: \n".to_utf8())


func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg("C", id, "\n%s\n%d\n%s" % [mid, index, sdp])


func send_offer(id, offer) -> int:
	return _send_msg("O", id, offer)


func send_answer(id, answer) -> int:
	return _send_msg("A", id, answer)


func _send_msg(type, id, data) -> int:
	return client.get_peer(1).put_packet(("%s: %d\n%s" % [type, id, data]).to_utf8())


func _process(delta):
	print("here")
	var status : int = client.get_connection_status()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		client.poll()
