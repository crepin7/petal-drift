extends Node2D
## Main menu screen — title, high score, start button.

@onready var title_label: Label = $CanvasLayer/TitleLabel
@onready var start_label: Label = $CanvasLayer/StartLabel
@onready var high_score_label: Label = $CanvasLayer/HighScoreLabel
@onready var instructions: Label = $CanvasLayer/Instructions
@onready var background: Node2D = $Background

var pulse_time: float = 0.0

func _ready() -> void:
	high_score_label.text = "Best: %d" % GameManager.high_score
	
	# Gentle entrance animation
	modulate = Color.TRANSPARENT
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.5)

func _process(delta: float) -> void:
	pulse_time += delta
	if start_label:
		var alpha := 0.5 + 0.5 * sin(pulse_time * 2.0)
		start_label.modulate.a = alpha

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			_start_game()

func _start_game() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
