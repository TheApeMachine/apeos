extends Node

func trace(function, argument):
	print(str(function, "(", argument, ")"))
	
	var file = File.new()
	file.open("res://fs/trace.log", file.READ_WRITE)
	
	var txt = file.get_as_text()
	if function == "main._on_add_buffer":
		txt += "\n"
	
	file.store_string(str(txt, function, "(", argument, ")", "\n"))
	file.close()
