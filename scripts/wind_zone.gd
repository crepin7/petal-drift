extends Area2D
## A wind current that pushes the petal in a direction.
##
## Golden/white flowing particle stream visible to the player.
## Stronger winds appear wider and faster.

enum WindDirection { LEFT, RIGHT, UP, DOWN }

var wind_strength: float = 100.0
var wind_dir: WindDirection = WindDirection.RIGHT
var wind_color: Color = Color(1.0, 0.95, 0.7, 0.4)

func _ready() -> void:
	add_to_group("wind")
	randomize()
	wind_strength = 50.0 + randf_range(-20.0, 80.0)
	wind_dir = randi() % 4 as WindDirection
	
	# Visual indicator
	_draw_wind_indicator()

func _draw_wind_indicator() -> void:
	# Create a visual stream using simple colored rectangles or particles
	var stream := $Stream as Node2D
	if not stream:
		return
	
	var dir_text := ""
	match wind_dir:
		WindDirection.LEFT:
			dir_text = "←"
		WindDirection.RIGHT:
			dir_text = "→"
		WindDirection.UP:
			dir_text = "↑"
		WindDirection.DOWN:
			dir_text = "↓"
	
	# Position a label or sprite showing direction
	var label := $DirectionLabel as Label
	if label:
		label.text = dir_text
		label.modulate = wind_color * Color(1, 1, 1, 0.5)
	
	# Size indicator for strength
	scale.x = 0.5 + wind_strength / 200.0

func get_wind_force() -> Vector2:
	match wind_dir:
		WindDirection.LEFT:
			return Vector2(-wind_strength, 0.0)
		WindDirection.RIGHT:
			return Vector2(wind_strength, 0.0)
		WindDirection.UP:
			return Vector2(0.0, -wind_strength)
		WindDirection.DOWN:
			return Vector2(0.0, wind_strength)
	return Vector2.ZERO
