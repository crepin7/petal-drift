extends Node2D
## Main game scene — spawns flowers, hazards, wind zones, and manages the world.

const SPAWN_INTERVAL: float = 1.2
const HAZARD_INTERVAL: float = 3.0
const WIND_INTERVAL: float = 4.0
const SCROLL_SPEED: float = 60.0

var screen_size: Vector2
var spawn_timer: float = 0.0
var hazard_timer: float = 0.0
var wind_timer: float = 0.0
var difficulty: float = 1.0
var game_time: float = 0.0

@onready var player: Area2D = $Player
@onready var background: Node2D = $Background
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var combo_label: Label = $CanvasLayer/ComboLabel
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI
@onready var final_score_label: Label = $CanvasLayer/GameOverUI/FinalScoreLabel
@onready var high_score_label: Label = $CanvasLayer/GameOverUI/HighScoreLabel
@onready var tap_to_restart: Label = $CanvasLayer/GameOverUI/TapToRestart
@onready var flower_spawner: Node2D = $FlowerSpawner
@onready var hazard_spawner: Node2D = $HazardSpawner
@onready var wind_spawner: Node2D = $WindSpawner

# Flower scene (created programmatically)
var flower_scene: PackedScene
var hazard_scene: PackedScene
var wind_scene: PackedScene

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# Connect signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.combo_updated.connect(_on_combo_updated)
	GameManager.game_over.connect(_on_game_over)
	
	player.flower_collected.connect(_on_player_collected_flower)
	
	# Hide game over UI
	game_over_ui.hide()
	
	# Pre-create scene templates (we'll instance them directly)
	# Since we're in code-only mode, create them via script
	_create_scene_templates()
	
	# Initial state
	score_label.text = "0"
	combo_label.text = ""

func _process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	
	game_time += delta
	difficulty = 1.0 + game_time * 0.02  # Gradually harder
	
	# Spawn timers
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL / difficulty:
		spawn_timer = 0.0
		_spawn_flower()
	
	hazard_timer += delta
	if hazard_timer >= HAZARD_INTERVAL / (difficulty * 0.5):
		hazard_timer = 0.0
		_spawn_hazard()
	
	wind_timer += delta
	if wind_timer >= WIND_INTERVAL:
		wind_timer = 0.0
		_spawn_wind_zone()

func _create_scene_templates() -> void:
	# Flower scene
	flower_scene = PackedScene.new()
	var flower_node := Area2D.new()
	flower_node.name = "Flower"
	flower_node.script = load("res://scripts/flower.gd")
	
	var flower_sprite := Polygon2D.new()
	flower_sprite.name = "FlowerSprite"
	flower_node.add_child(flower_sprite)
	
	var flower_glow := Sprite2D.new()
	flower_glow.name = "GlowSprite"
	flower_node.add_child(flower_glow)
	
	var flower_collision := CollisionShape2D.new()
	flower_collision.name = "CollisionShape2D"
	flower_collision.shape = CircleShape2D.new()
	flower_collision.shape.radius = 15.0
	flower_node.add_child(flower_collision)
	
	var despawn_timer := Timer.new()
	despawn_timer.name = "DespawnTimer"
	despawn_timer.one_shot = true
	flower_node.add_child(despawn_timer)
	
	# Reparent for ownership
	for child in flower_node.get_children():
		child.owner = flower_node
	flower_node.owner = flower_node
	
	flower_scene.pack(flower_node)
	flower_node.free()
	
	# Hazard scene
	hazard_scene = PackedScene.new()
	var hazard_node := Area2D.new()
	hazard_node.name = "Hazard"
	hazard_node.script = load("res://scripts/hazard.gd")
	
	var hazard_sprite := Sprite2D.new()
	hazard_sprite.name = "CloudSprite"
	hazard_node.add_child(hazard_sprite)
	
	var hazard_collision := CollisionShape2D.new()
	hazard_collision.name = "CollisionShape2D"
	hazard_collision.shape = CircleShape2D.new()
	hazard_collision.shape.radius = 40.0
	hazard_node.add_child(hazard_collision)
	
	for child in hazard_node.get_children():
		child.owner = hazard_node
	hazard_node.owner = hazard_node
	
	hazard_scene.pack(hazard_node)
	hazard_node.free()
	
	# Wind zone scene
	wind_scene = PackedScene.new()
	var wind_node := Area2D.new()
	wind_node.name = "WindZone"
	wind_node.script = load("res://scripts/wind_zone.gd")
	
	var wind_stream := Node2D.new()
	wind_stream.name = "Stream"
	wind_node.add_child(wind_stream)
	
	var direction_label := Label.new()
	direction_label.name = "DirectionLabel"
	wind_node.add_child(direction_label)
	
	var wind_collision := CollisionShape2D.new()
	wind_collision.name = "CollisionShape2D"
	wind_collision.shape = RectangleShape2D.new()
	wind_collision.shape.size = Vector2(200, 100)
	wind_node.add_child(wind_collision)
	
	for child in wind_node.get_children():
		child.owner = wind_node
	wind_node.owner = wind_node
	
	wind_scene.pack(wind_node)
	wind_node.free()

func _spawn_flower() -> void:
	if not flower_scene:
		return
	var flower := flower_scene.instantiate()
	var x := randf_range(50.0, screen_size.x - 50.0)
	var y := screen_size.y + 40.0
	flower.position = Vector2(x, y)
	flower_spawner.add_child(flower)

func _spawn_hazard() -> void:
	if not hazard_scene:
		return
	var hazard := hazard_scene.instantiate()
	var x := randf_range(50.0, screen_size.x - 50.0)
	var y := screen_size.y + 40.0 + randf_range(0, 200.0)
	hazard.position = Vector2(x, y)
	hazard_spawner.add_child(hazard)

func _spawn_wind_zone() -> void:
	if not wind_scene:
		return
	var wind := wind_scene.instantiate()
	var x := randf_range(50.0, screen_size.x - 50.0)
	var y := screen_size.y + 40.0
	wind.position = Vector2(x, y)
	wind_spawner.add_child(wind)

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_combo_updated(combo: int) -> void:
	if combo > 1:
		combo_label.text = "x%d" % combo
		# Pop animation
		var tween := create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
	else:
		combo_label.text = ""

func _on_player_collected_flower(position: Vector2) -> void:
	# Emit particles at flower position
	_spawn_burst_particles(position)

func _spawn_burst_particles(pos: Vector2) -> void:
	# Simple burst using ColorRect particles
	var burst_particle := ColorRect.new()
	burst_particle.color = Color(1.0, 0.85, 0.4, 0.8)
	burst_particle.size = Vector2(8, 8)
	burst_particle.position = pos
	add_child(burst_particle)
	
	var tween := create_tween()
	tween.tween_property(burst_particle, "position", pos + Vector2(randf_range(-50, 50), randf_range(-50, 50)), 0.5)
	tween.parallel().tween_property(burst_particle, "color:a", 0.0, 0.5)
	tween.tween_callback(burst_particle.queue_free)

func _on_game_over(score: int) -> void:
	game_over_ui.show()
	final_score_label.text = "Score: %d" % score
	high_score_label.text = "Best: %d" % GameManager.high_score
	
	# Pulsing restart text
	var tween := create_tween()
	tween.tween_property(tap_to_restart, "modulate:a", 0.3, 0.8)
	tween.tween_property(tap_to_restart, "modulate:a", 1.0, 0.8)
	tween.set_loops()
	
	# Wait for tap to restart
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not GameManager.is_playing and game_over_ui.visible:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed:
				# Restart
				GameManager.start_game()
				get_tree().reload_current_scene()
