extends Control

signal add_seq(content)

onready var buffer = get_parent().get_parent()
onready var root   = buffer.get_parent()

func _ready():
	connect("add_seq", root, "_on_add_seq")

func _input(event):
	if event.is_pressed():
		if event.scancode == KEY_ENTER:
			handle_command($TextEdit.get_text())

func handle_command(str_cmd: String) -> void:
	logger.trace("terminal.handle_command", str_cmd)
	var arr_cmd = str_cmd.split(" ")
	
	match arr_cmd[0]:
		"test":
			emit_signal("add_seq", "github.com/theapemachine/boopy")
		_:
			var output = []
			OS.execute(arr_cmd[0], [], true, output)
			
			for out in output:
				$TextEdit.set_text(str($TextEdit.get_text(), out))

func grab_focus():
	logger.trace("terminal.grab_focus", "")
	$TextEdit.grab_focus()

func play_buffer() -> void:
	logger.trace("terminal.play_buffer", "")
