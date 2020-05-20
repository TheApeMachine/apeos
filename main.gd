extends Spatial

signal add_buffer(buffer_type, content)
signal grab_focus(buffer_target)
signal play_buffer()

var locks: Array = []
var queue: Array = []

var buffers: Array = []
onready var buffer = preload("res://buffer.tscn")

var seqs: Array = []
onready var seq = preload("res://bin/seq.tscn")

var cam_pointer: int = 0
var should_lerp: bool = true

var server: Server
var client: Client

func _ready() -> void:
	connect("add_buffer", self, "_on_add_buffer")
	connect("grab_focus", self, "_on_grab_focus")
	connect("play_buffer", self, "_on_play_buffer")

	server = Server.new()
	server.listen(1235)
	
	client = Client.new()

func _input(event) -> void:
	if event.is_pressed():
		if event.scancode == KEY_CONTROL:
			should_lerp = false
			$Camera.transform.origin -= Vector3(0.0, -0.1, 0.1)
		else:
			if event.scancode == KEY_SEMICOLON:
				emit_signal("add_buffer", "terminal")
			elif event.scancode == KEY_LEFT:
				emit_signal("grab_focus", "prev")
			elif event.scancode == KEY_RIGHT:
				emit_signal("grab_focus", "next")
			elif event.scancode == KEY_ALT:
				should_lerp = true

func _process(delta):
	var msg = client.poll()
	
	if len(buffers) > 0 && should_lerp:
		$Camera.global_transform.origin = lerp(
			$Camera.transform.origin,
			buffers[cam_pointer].transform.origin - Vector3(0.5, 0.0, -0.89),
			delta * 4.0
		)

func position_buffers() -> void:
	for i in range(buffers.size()):
		buffers[i].transform.origin = Vector3(i, 0.0, 0.0)

func position_camera() -> void:
	$Camera.transform.origin = buffers[cam_pointer].transform.origin - Vector3(0.5, 0.0, -0.89)

func queue_buffer(buffer_target, action) -> void:
	queue.append([buffer_target, action])

func _on_grab_focus(buffer_target) -> void:
	if len(locks) < 2:
		logger.trace("main._on_grab_focus", buffer_target)
		match buffer_target:
			"prev":
				cam_pointer -= 1
			"next":
				cam_pointer += 1

		if !$Move.playing:
			$Move.play()
		#position_camera()
	else:
		queue_buffer("next", "grab_focus")

func _on_add_buffer(buffer_type: String, content: String = "") -> void:
	logger.trace("main._on_add_buffer", buffer_type)
	var buffer_instance = buffer.instance()
	buffer_instance.init(buffer_type, content)
	buffers.append(buffer_instance)
	add_child(buffer_instance)
	position_buffers()

func _on_kill_buffer(buffer_instance) -> void:
	logger.trace("main._on_kill_buffer", buffer_instance)
	buffers.erase(buffer_instance)
	buffer_instance.queue_free()
	position_buffers()

func _on_play_buffer() -> void:
	if len(locks) < 2:
		logger.trace("main._on_play_buffer", "")
		buffers[cam_pointer].play_buffer()
	else:
		queue_buffer(buffers[cam_pointer], "play_buffer")

func _on_add_seq(content: String) -> void:
	logger.trace("main._on_add_seq", content)
	var seq_instance = seq.instance()
	seq_instance.init(content)
	seqs.append(seq_instance)
	add_child(seq_instance)

func _on_add_lock(buffer_target) -> void:
	logger.trace("main._on_add_lock", buffer_target)
	locks.append(buffer_target)

func _on_remove_lock(buffer_target) -> void:
	logger.trace("main._on_remove_lock", buffer_target)
	locks.erase(buffer_target)
	logger.trace("main.locks", locks)

	if len(locks) == 0:
		logger.trace("main.queue", queue)

		for i in range(4):
			var q = queue.pop_front()

			if q[1] == "grab_focus":
				emit_signal("grab_focus", q[0])
			elif q[1] == "play_buffer":
				emit_signal("play_buffer")
