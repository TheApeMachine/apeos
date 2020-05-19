extends Control

signal add_lock(buffer_target)
signal remove_lock(buffer_target)

var content: String
var count: int = 0
var t

onready var buffer = get_parent().get_parent()
onready var root   = buffer.get_parent()
onready var label  = $RichTextLabel

func _ready():
	connect("add_lock", root, "_on_add_lock")
	connect("remove_lock", root, "_on_remove_lock")

func _on_t_timeout():
	if count < len(content):
		label.add_text(content[count])
		count += 1
	else:
		emit_signal("remove_lock", buffer)
		t.stop()
		
func set_content(content_path: String) -> void:
	logger.trace("cat.set_content", content_path)
	var f = File.new()
	f.open(str("res://fs/", content_path), f.READ)
	content = f.get_as_text()
	f.close()
	$RichTextLabel.set_scroll_follow(true)
	$RichTextLabel.push_mono()

func grab_focus() -> void:
	pass

func play_buffer() -> void:
	emit_signal("add_lock", buffer)
	
	logger.trace("cat.play_buffer", "")
	t = Timer.new()
	t.set_wait_time(0.005)
	t.connect("timeout", self, "_on_t_timeout")
	t.autostart = true
	add_child(t)
	t.start()
