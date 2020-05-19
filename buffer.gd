extends Spatial

var buffer_type
var buffer_content
var ui

onready var viewport = $Viewport

func _input(event) -> void:
	viewport.input(event)

func _ready() -> void:
	if buffer_type == "video":
		$MeshInstance.scale = Vector3(0.9, 0.6, 1.0)
		$MeshInstance.transform.origin = Vector3(0.0, 0.0, -0.25)
	else:
		$MeshInstance.scale = Vector3(0.9, 0.9, 1.0)
		
	load_ui()
	grab_focus()
	
func load_ui() -> void:
	ui = load(str("res://ui/", buffer_type, ".tscn")).instance()
	viewport.add_child(ui)

func grab_focus() -> void:
	match buffer_type:
		"terminal":
			$WindowOpen.play()
			ui.grab_focus()
		"cat":
			ui.set_content(buffer_content)
		"video":
			ui.set_content(buffer_content)

func play_buffer() -> void:
	ui.play_buffer()

func init(bt: String, bc: String = "") -> void:
	logger.trace("buffer.init", bt)
	buffer_type    = bt
	buffer_content = bc
