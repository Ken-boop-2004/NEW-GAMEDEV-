extends CanvasLayer

@onready var panel: Control = $PausePanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	$PausePanel/VBoxContainer/BtnContinue.pressed.connect(_on_continue)
	$PausePanel/VBoxContainer/BtnExit.pressed.connect(_on_exit)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if get_tree().paused:
				_on_continue()
			else:
				_pause()

func _pause() -> void:
	get_tree().paused = true
	panel.show()

func _on_continue() -> void:
	get_tree().paused = false
	panel.hide()

func _on_exit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
