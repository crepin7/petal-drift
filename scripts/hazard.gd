extends Area2D
## A dark cloud that pushes the petal downward.
##
## Clouds drift slowly across the screen and have a pulsing dark aura.
## Touching one damages the petal and pushes it down.

var push_strength: float = 80.0
var drift_speed: Vector2 = Vector2.ZERO
var lifetime: float = 10.0

@onready var cloud_sprite: Sprite2D = $CloudSprite

func _ready() -> void:
	add_to_group("hazard")
	
	drift_speed = Vector2(
		randf_range(-15.0, 15.0),
		randf_range(-5.0, -10.0)  # Drift upward slowly
	)
	
	_draw_cloud()
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.6, 2.0)
	tween.tween_property(self, "modulate:a", 0.9, 2.0)
	tween.set_loops()
	
	# Despawn
	get_tree().create_timer(lifetime).timeout.connect(_fade_out)

func _process(delta: float) -> void:
	position += drift_speed * delta
	
	# Gentle pulse
	if cloud_sprite:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.002) * 0.05
		cloud_sprite.scale = Vector2(pulse, pulse)

func _draw_cloud() -> void:
	if not cloud_sprite:
		return
	if cloud_sprite is Sprite2D:
		# Use a simple circle-like shape
		cloud_sprite.texture = null  # Will draw with modulate
	cloud_sprite.modulate = Color(0.2, 0.1, 0.35, 0.7)
	cloud_sprite.scale = Vector2(1.5, 0.8)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Extra push down on contact
		var push := Vector2(0.0, push_strength)
		if body.has_method("apply_force"):
			body.apply_force(push)
