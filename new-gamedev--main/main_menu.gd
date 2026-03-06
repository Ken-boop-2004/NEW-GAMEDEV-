extends Control

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	$VBoxContainer/BtnPlay.pressed.connect(_on_play)
	$VBoxContainer/BtnSettings.pressed.connect(_on_settings)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit)
	
	# Make sure video is playing
	if not video.is_playing():
		video.play()

func _on_play() -> void:
	video.stop()
	get_tree().change_scene_to_file("res://level.tscn")

func _on_settings() -> void:
	video.stop()
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_quit() -> void:
	get_tree().quit()
