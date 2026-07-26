extends Node
## Global game manager — tracks score, combo, game state, and scene transitions.

signal score_changed(new_score: int)
signal combo_updated(combo: int)
signal game_over(score: int)
signal game_started

var score: int = 0
var combo: int = 0
var high_score: int = 0
var is_playing: bool = false

const SAVE_FILE: String = "user://petal_drift_save.dat"

func _ready() -> void:
	load_high_score()

func add_score(points: int) -> void:
	score += points * max(1, combo)
	score_changed.emit(score)

func increment_combo() -> void:
	combo += 1
	combo_updated.emit(combo)

func reset_combo() -> void:
	combo = 0
	combo_updated.emit(combo)

func start_game() -> void:
	score = 0
	combo = 0
	is_playing = true
	game_started.emit()

func end_game() -> void:
	is_playing = false
	if score > high_score:
		high_score = score
		save_high_score()
	game_over.emit(score)

func load_high_score() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		high_score = file.get_32()
		file.close()

func save_high_score() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
