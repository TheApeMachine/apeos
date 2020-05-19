extends Control

signal add_lock(buffer_target)
signal remove_lock(buffer_target)

var content: String
var playing: bool = false

onready var buffer = get_parent().get_parent()
onready var root   = buffer.get_parent()

func _ready():
	connect("add_lock", root, "_on_add_lock")
	connect("remove_lock", root, "_on_remove_lock")

func _process(_delta):
	if $VideoPlayer.stream_position != 0:
		playing = true 
		
	if playing && !$VideoPlayer.is_playing():
		playing = false
		emit_signal("remove_lock", buffer)

func set_content(content_path: String) -> void:
	logger.trace("video.set_content", content_path)
	$VideoPlayer.set_stream(load(str("res://fs/", content_path)))

func grab_focus() -> void:
	pass

func play_buffer() -> void:
	emit_signal("add_lock", buffer)
	logger.trace("video.play_buffer", "")
	$VideoPlayer.play()
