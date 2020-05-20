extends Node

class_name Server

const TIMEOUT = 1000
var shares: Dictionary = {}
var peers: Dictionary = {}
var server: WebSocketServer = WebSocketServer.new()

const ALFNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
var _alfnum = ALFNUM.to_ascii()
var rand: RandomNumberGenerator = RandomNumberGenerator.new()

class Peer extends Reference:
	
	var id = -1
	var share = ""
	var time = OS.get_ticks_msec()
	
	func _init(peer_id):
		id = peer_id

class Share extends Reference:
	
	var peers: Array = []
	var host: int = -1
	var sealed: bool = false
	
	func _init(host_id: int):
		host = host_id

	func join(peer_id, server) -> bool:
		if sealed: return false
		if not server.has_peer(peer_id): return false

		var new_peer : WebSocketPeer = server.get_peer(peer_id)
		new_peer.put_packet(("I: %d\n" % (1 if peer_id == host else peer_id)).to_utf8())

		for p in peers:
			if not server.has_peer(p):
				continue

			server.get_peer(p).put_packet(("N: %d\n" % peer_id).to_utf8())
			new_peer.put_packet(("N: %d\n" % (1 if p == host else p)).to_utf8())

		peers.push_back(peer_id)
		return true

	func leave(peer_id, server) -> bool:
		if not peers.has(peer_id): return false
		
		peers.erase(peer_id)
		var close = false
		
		if peer_id == host:
			# The room host disconnected, will disconnect all peers.
			close = true
			
		if sealed: return close
		
		# Notify other peers.
		for p in peers:
			if not server.has_peer(p): return close
			if close:
				# Disconnect peers.
				server.disconnect_peer(p)
			else:
				# Notify disconnection.
				server.get_peer(p).put_packet(("D: %d\n" % peer_id).to_utf8())
		return close

	func seal(peer_id, server) -> bool:
		# Only host can seal the room.
		if host != peer_id: return false
	
		sealed = true
		
		for p in peers:
			server.get_peer(p).put_packet("S: \n".to_utf8())
		
		return true

func _init():
	server.connect("data_received", self, "_on_data")
	server.connect("client_connected", self, "_peer_connected")
	server.connect("client_disconnected", self, "_peer_disconnected")

func _process(delta):
	poll()

func listen(port):
	stop()
	rand.seed = OS.get_unix_time()
	server.listen(port)

func stop():
	server.stop()
	peers.clear()

func poll():
	if not server.is_listening():
		return

	server.poll()

func _peer_connected(id, protocol = ""):
	peers[id] = Peer.new(id)

func _peer_disconnected(id, was_clean = false):
	var share = peers[id].share
	print("Peer %d disconnected from share: '%s'" % [id, share])

	if share and shares.has(share):
		peers[id].share = ""

		if shares[share].leave(id, server):
			# If true, share host has disconnected, so delete it.
			print("Deleted share %s" % share)
			shares.erase(share)

	peers.erase(id)

func _join_share(peer, share) -> bool:
	if share == "":
		for _i in range(0, 32):
			share += char(_alfnum[rand.randi_range(0, ALFNUM.length()-1)])
		shares[share] = Share.new(peer.id)
	
	elif not shares.has(share):
		return false
		
	shares[share].join(peer.id, server)
	peer.share = share

	# Notify peer of its lobby
	server.get_peer(peer.id).put_packet(("join_share %s\n" % share).to_utf8())

	print("Peer %d joined share: '%s'" % [peer.id, share])
	return true

func _on_data(id):
	var pkt_str: String = server.get_peer(id).get_packet().get_string_from_utf8()
	
	for p in peers:
		p.put_packet(pkt_str).to_utf8()
