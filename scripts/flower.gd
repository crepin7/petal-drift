extends Area2D
## A glowing flower floating upward. Land on it to score and bounce.
##
## Flowers come in different colors and sizes.
## They drift upward slowly and fade out after a while.

enum FlowerColor { PINK, ORANGE, YELLOW, WHITE, CYAN }

const COLORS: Dictionary = {
	FlowerColor.PINK: Color(1.0, 0.4, 0.7, 1.0),
	FlowerColor.ORANGE: Color(1.0, 0.6, 0.2, 1.0),
	FlowerColor.YELLOW: Color(1.0, 0.9, 0.3, 1.0),
	FlowerColor.WHITE: Color(0.9, 0.95, 1.0, 1.0),
	FlowerColor.CYAN: Color(0.3, 0.85, 1.0, 1.0)
}

var color_variant: FlowerColor = FlowerColor.PINK
var float_speed: float = 40.0 + randf_range(-10.0, 10.0)
var size: float = 1.0
var lifetime: float = 8.0
var age: float = 0.0
var collected: bool = false

@onready var sprite: Node2D = $FlowerSprite
@onready var glow: Sprite2D = $GlowSprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var despawn_timer: Timer = $DespawnTimer

func _ready() -> void:
	add_to_group("flower")
	
	# Randomize look
	color_variant = randi() % COLORS.size() as FlowerColor
	size = 0.7 + randf_range(-0.15, 0.15)
	
	if sprite:
		_draw_flower_shape()
	if glow:
		glow.modulate = Color(COLORS[color_variant].r, COLORS[color_variant].g, COLORS[color_variant].b, 0.3)
		glow.scale = Vector2(2.5, 2.5) * size
	
	# Random rotation
	rotation = randf_range(0.0, TAU)
	
	# Despawn timer
	despawn_timer.wait_time = lifetime
	despawn_timer.start()
	despawn_timer.timeout.connect(_on_despawn)

func _process(delta: float) -> void:
	if collected:
		return
	
	# Float upward
	position.y -= float_speed * delta
	
	# Gentle sway
	position.x += sin(Time.get_ticks_msec() * 0.001 * 1.5 + position.y * 0.01) * 0.3
	
	# Age
	age += delta
	var fade := 1.0
	var remaining := despawn_timer.time_left
	if remaining < 2.0:
		fade = remaining / 2.0
	modulate.a = fade
	
	# Rotate slowly
	rotation += delta * 0.3

func _draw_flower_shape() -> void:
	if not sprite:
		return
	if sprite is Polygon2D:
		var petals := PackedVector2Array()
		var num_petals := 5
		for i in range(num_petals):
			var angle := (float(i) / float(num_petals)) * TAU - PI / 2.0
			var r := 8.0 * size
			var tip := Vector2(cos(angle), sin(angle)) * r
			# Each petal: two control points for a rounded teardrop
			var left := Vector2(cos(angle + 0.4), sin(angle + 0.4)) * r * 0.5
			var right := Vector2(cos(angle - 0.4), sin(angle - 0.4)) * r * 0.5
			petals.append_array([tip, left, Vector2.ZERO, right])
		sprite.polygon = petals
		sprite.color = COLORS[color_variant]

func collect() -> void:
	if collected:
		return
	collected = true
	# Burst animation
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
		tween.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.3)
		tween.tween_callback(queue_free)
	collision.set_deferred("disabled", true)

func _on_despawn() -> void:
	if not collected:
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
		tween.tween_callback(queue_free)
