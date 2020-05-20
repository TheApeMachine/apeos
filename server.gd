extends Node

const ALFNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
var _alfnum = ALFNUM.to_ascii()
var rand: RandomNumberGenerator = RandomNumberGenerator.new()
var shares: Dictionary = {}
var server: WebSocketServer = WebSocketServer.new()
var peers: Dictionary = {}

class Peer extends Reference:
	
	var id = -1
	var share = ""
	
	func _init(peer_id):
		logger.trace("server.Peer._init", peer_id)
		id = peer_id
		
class Share extends Reference:
	
	var peers: Array = []
	var host: int = -1
	var sealed: bool = false
	
	func _init(host_id: int):
		logger.trace("server.Share._init", host_id)
		host = host_id
		
	func join(peer_id, server) -> bool:
		logger.trace("server.Share.join", peer_id + "," + server)

		if sealed: return false
		if not server.has_peer(peer_id): return false
		
		var new_peer: WebSocketPeer = server.get_peer(peer_id)
		new_peer.put_packet(("connected %d\n" % (1 if peer_id == host else peer_id)).to_utf8())
		
		for p in peers:
			if not server.has_peer(p):
				continue
				
			server.get_peer(p).put_packet(("peer_connected %d\n" % peer_id).to_utf8())
			new_peer.put_packet(("peer_connected %d\n" % (1 if p == host else p)).to_utf8())
			
		peers.push_back(peer_id)
		return true
	
	func leave(peer_id, server) -> bool:
		logger.trace("server.Share.leave", peer_id + "," + server)
		
		if not peers.has(peer_id): return false
		
		peers.erase(peer_id)
		var close = false
		
		if peer_id == host:
			close = true
			
		for p in peers:
			if not server.has_peer(p): return close
			
			if close:
				server.disconnect_peer(p)
			else:
				server.get_peer(p).put_packet(("peer_disconnected %d\n" % peer_id).to_utf8())
				
		return close

	func seal(peer_id, server) -> bool:
		logger.trace("server.Share.seal", peer_id + "," + server)

		if host != peer_id: return false
		sealed = true
		
		for p in peers:
			server.get_peer(p).put_packet("seal_share\n").to_utf8()
			
		return true
		
func _init():
	logger.trace("server._init", "")
	
	server.connect("data_received", self, "_on_data")
	server.connect("client_connected", self, "_peer_connected")
	server.connect("client_disconnected", self, "_peer_disconnected")
	
func _process(delta):
	poll()
	
func listen(port):
	logger.trace("server.listen", port)
	
	stop()
	rand.seed = OS.get_unix_time()
	server.listen(port)

func stop():
	logger.trace("server.stop()", "")

	server.stop()
	peers.clear()
	
func poll():
	if not server.is_listening():
		return
		
	server.poll()

func _peer_connected(id, protocol=""):
	logger.trace("server._peer_connected", id)
	peers[id] = Peer.new(id)
	
func _peer_disconnected(id, was_clean=false):
	logger.trace("server._peer_disconnected", id)

	var share = peers[id].share
	
	if share and shares.has(share):
		peers[id].share = ""
		
		if shares[share].leave(id, server):
			shares.erase(share)
			
	peers.erase(id)
	
func _join_share(peer, share) -> bool:
	logger.trace("server._join_share", peer + "," + share)

	if share == "":
		for i in range(0, 32):
			share += char(_alfnum[rand.randi_range(0, ALFNUM.length()-1)])
		
		shares[share] = Share.new(peer.id)
		
	elif not shares.has(share):
		return false
		
	shares[share].join(peer.id, server)
	peer.share = share
	server.get_peer(peer.id).put_packet(("join_share %s\n" % share).to_utf8())
	return true

func _on_data(id):
	logger.trace("server._on_data", id)

	if not _parse_msg(id):
		server.disconnect_peer(id)

func _parse_msg(id) -> bool:
	var pkt_str: String = server.get_peer(id).get_packet().get_string_from_utf8()
	logger.trace("server._parse_msg", pkt_str)
	return true
