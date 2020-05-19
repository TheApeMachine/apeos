extends Spatial

signal add_buffer(buffer_type, content)
signal grab_focus(buffer_target)
signal play_buffer()

var content_path: String
var str_script: String

onready var root = get_parent()

func _ready() -> void:
	connect("add_buffer", root, "_on_add_buffer")
	connect("grab_focus", root, "_on_grab_focus")
	connect("play_buffer", root, "_on_play_buffer")

	grab_focus()

func init(cp: String) -> void:
	logger.trace("seq.init", cp)
	content_path = cp
	var f = File.new()
	f.open(str("res://fs/", content_path, "/script.ape"), f.READ)
	str_script = f.get_as_text()
	f.close()

func grab_focus() -> void:
	logger.trace("seq.grab_focus", "")
	
	for action in str_script.split("\n"):
		var arr_action = action.split(" ")
		match arr_action[0]:
			"add_buffer":
				emit_signal(arr_action[0], arr_action[1], arr_action[2])
			"play_buffer":
				emit_signal(arr_action[0])
			"grab_focus":
				emit_signal(arr_action[0], arr_action[1])
