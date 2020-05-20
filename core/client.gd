extends "webrtc_client.gd"

var rtc_mp: WebRTCMultiplayer = WebRTCMultiplayer.new()
var sealed = false

func _init():
	logger.trace("client._init", "")
	connect("connected", self, "connected")
	connect("disconnected", self, "disconnected")
	connect("offer_received", self, "offer_received")
	connect("answer_received", self, "answer_received")
	connect("candidate_received", self, "candidate_received")
	connect("share_joined", self, "share_joined")
	connect("share_sealed", self, "share_sealed")
	connect("peer_connected", self, "peer_connected")
	connect("peer_disconnected", self, "peer_disconnected")
	
func start(url, share=""):
	logger.trace("client.start", url + "," + share)
	
	stop()
	sealed = false
	self.share = share
	connect_to_url(url)
	
func stop():
	logger.trace("client.stop", "")

	rtc_mp.close()
	close()
	
func _create_peer(id):
	logger.trace("client._create_peer", id)
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	
	peer.initialize({
		"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]
	})
	
	peer.connect("session_description_created", self, "_offer_created", [id])
	peer.connect("ice_candiate_created", self, "_new_ice_candiate", [id])
	rtc_mp.add_peer(peer, id)
	
	if id > rtc_mp.get_unique_id():
		peer.create_offer()
		
	return peer
	
func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	logger.trace("client._new_ice_candidate", mid_name + "," + index_name + "," + sdp_name + "," + id)
	send_candidate(id, mid_name, index_name, sdp_name)
	
func _offer_created(type, data, id):
	logger.trace("client._offer_created", type + "," + data + "," + id)

	if not rtc_mp.has_peer(id):
		return
		
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer": send_offer(id, data)
	else: send_answer(id, data)
	
func connected(id):
	logger.trace("client.connected", id)
	rtc_mp.initialize(id, true)
	
func share_joined(share):
	logger.trace("client.share_joined", share)
	self.share = share

func share_sealed():
	logger.trace("client.share_sealed", "")
	sealed = true
	
func disconnected():
	logger.trace("client.disconnected", "")
	if not sealed:
		stop()

func peer_connected(id):
	logger.trace("client.peer_connected", id)
	_create_peer(id)
	
func peer_disconnected(id):
	logger.trace("client.peer_disconnected", id)
	if rtc_mp.has_peer(id): rtc_mp.remove_peer(id)
	
func offer_received(id, offer):
	logger.trace("client.offer_received", id + "," + offer)
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)
		
func answer_received(id, answer):
	logger.trace("client.answer_received", id + "," + answer)
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("answer", answer)

func candidate_received(id, mid, index, sdp):
	logger.trace("client.candidate_received", id + "," + mid + "," + index + "," + sdp)
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)
