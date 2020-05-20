extends "webrtc_client.gd"

class_name MultiplayerClient

var rtc_mp: WebRTCMultiplayer = WebRTCMultiplayer.new()
var sealed = false

func _init():
	connect("connected", self, "connected")
	connect("disconnected", self, "disconnected")

	connect("offer_received", self, "offer_received")
	connect("answer_received", self, "answer_received")
	connect("candidate_received", self, "candidate_received")

	connect("share_joined", self, "share_joined")
	connect("share_sealed", self, "share_sealed")
	connect("peer_connected", self, "peer_connected")
	connect("peer_disconnected", self, "peer_disconnected")


func start(url, share = ""):
	stop()
	sealed = false
	self.share = share
	connect_to_url(url)


func stop():
	rtc_mp.close()
	close()


func _create_peer(id):
	var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	peer.connect("session_description_created", self, "_offer_created", [id])
	peer.connect("ice_candidate_created", self, "_new_ice_candidate", [id])
	rtc_mp.add_peer(peer, id)
	if id > rtc_mp.get_unique_id():
		peer.create_offer()
	return peer


func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	send_candidate(id, mid_name, index_name, sdp_name)


func _offer_created(type, data, id):
	if not rtc_mp.has_peer(id):
		return
	print("created", type)
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer": send_offer(id, data)
	else: send_answer(id, data)


func connected(id):
	print("Connected %d" % id)
	rtc_mp.initialize(id, true)


func share_joined(share):
	self.share = share


func share_sealed():
	sealed = true


func disconnected():
	print("Disconnected: %d: %s" % [code, reason])
	if not sealed:
		stop() # Unexpected disconnect


func peer_connected(id):
	print("Peer connected %d" % id)
	_create_peer(id)


func peer_disconnected(id):
	if rtc_mp.has_peer(id): rtc_mp.remove_peer(id)


func offer_received(id, offer):
	print("Got offer: %d" % id)
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)


func answer_received(id, answer):
	print("Got answer: %d" % id)
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("answer", answer)


func candidate_received(id, mid, index, sdp):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)
