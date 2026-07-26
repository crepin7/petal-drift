extends Area2D
## The player's petal — drifts through the cosmos steered by touch.
##
## Left half of screen → drift left, right half → drift right.
## Release touch → gentle float upward.
## Colliding with a flower scores points and bounces you up.
## Falling below screen edge triggers game over.

signal flower_collected(flower_position: Vector2)

# Movement constants
const BASE_GRAVITY: float = 180.0
const DRIFT_ACCEL: float = 600.0
const DRIFT_DAMP: float = 5.0
const FLOAT_SPEED: float = -120.0
const MAX_FALL_SPEED: float = 400.0
const BOUNCE_SPEED: float = -350.0
const WOBBLE_SPEED: float = 2.0
const WOBBLE_AMOUNT: float = 0.15
const MAX_HEALTH: float = 100.0

var velocity: Vector2 = Vector2.ZERO
var wind_force: Vector2 = Vector2.ZERO
var is_touching_left: bool = false
var is_touching_right: bool = false
var is_floating: bool = false
var health: float = MAX_HEALTH
var screen_size: Vector2
var drift_target: float = 0.0

@onready var sprite: Node2D = $PetalSprite
@onready var glow: Node2D = $Glow
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var bounce_timer: Timer = $BounceTimer
@onready var petal_shape: PackedVector2Array = _make_petal_shape()

func _ready() -> void:
	screen_size = get_viewport_rect().size
	position = Vector2(screen_size.x / 2.0, screen_size.y * 0.7)
	
	# Draw the petal shape procedurally
	_draw_petal()
	
	if glow:
		_draw_glow()
	
	bounce_timer.timeout.connect(_on_bounce_timeout)

func _process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	
	# Wind from zones
	velocity += wind_force * delta
	
	# Touch-based drifting
	var drift_input: float = 0.0
	if is_touching_left:
		drift_input -= 1.0
	if is_touching_right:
		drift_input += 1.0
	
	drift_target = drift_input
	velocity.x += (drift_target * DRIFT_ACCEL - velocity.x) * delta * DRIFT_DAMP
	
	# Vertical movement — release to float, otherwise gravity
	if is_floating and drift_input == 0.0:
		velocity.y += (FLOAT_SPEED - velocity.y) * delta * 3.0
	else:
		velocity.y += BASE_GRAVITY * delta
	
	velocity.y = clamp(velocity.y, -500.0, MAX_FALL_SPEED)
	
	# Apply movement
	position += velocity * delta
	
	# Screen wrap horizontal
	if position.x < -50:
		position.x = screen_size.x + 50
	elif position.x > screen_size.x + 50:
		position.x = -50
	
	# Gentle wobble animation
	if sprite:
		var wobble := sin(Time.get_ticks_msec() * 0.001 * WOBBLE_SPEED) * WOBBLE_AMOUNT
		sprite.rotation = wobble + velocity.x * 0.001
	
	# Check game over — fell below screen
	if position.y > screen_size.y + 100:
		GameManager.end_game()

func _draw_petal() -> void:
	if not sprite:
		return
	
	var poly := PackedVector2Array()
	var steps := 16
	for i in range(steps):
		var t := float(i) / float(steps) * TAU
		# Tear-drop shape
		var r := 12.0
		var x := sin(t) * r * (0.5 + 0.5 * cos(t) * -0.3 + 0.5)
		var y := cos(t) * r * 1.2 - 4.0
		poly.append(Vector2(x, y))
	
	if sprite is Polygon2D:
		sprite.polygon = poly
		sprite.color = Color(1.0, 0.85, 0.4, 1.0)  # Warm golden

func _draw_glow() -> void:
	if not glow or not (glow is Sprite2D):
		return
	# Simple approach: just position the glow behind the petal
	glow.scale = Vector2(3.0, 3.0)
	glow.modulate = Color(1.0, 0.85, 0.4, 0.25)

func _make_petal_shape() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 16
	for i in range(steps):
		var t := float(i) / float(steps) * TAU
		var r := 12.0
		var x := sin(t) * r * (0.5 + 0.5 * cos(t) * -0.3 + 0.5)
		var y := cos(t) * r * 1.2 - 4.0
		pts.append(Vector2(x, y))
	return pts

func bounce() -> void:
	velocity.y = BOUNCE_SPEED
	bounce_timer.start(0.3)
	# Flash white briefly
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.4, 1.0), 0.3)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		GameManager.end_game()

func _on_bounce_timeout() -> void:
	pass

func _input(event: InputEvent) -> void:
	if not GameManager.is_playing:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_x: float = event.position.x
			var half := screen_size.x / 2.0
			if touch_x < half:
				is_touching_left = true
				is_touching_right = false
			else:
				is_touching_right = true
				is_touching_left = false
			is_floating = false
		else:
			is_touching_left = false
			is_touching_right = false
			is_floating = true
	
	# Mouse fallback for testing
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var half := screen_size.x / 2.0
				if event.position.x < half:
					is_touching_left = true
					is_touching_right = false
				else:
					is_touching_right = true
					is_touching_left = false
				is_floating = false
			else:
				is_touching_left = false
				is_touching_right = false
				is_floating = true

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("flower"):
		body.collect()
		flower_collected.emit(body.position)
		bounce()
		GameManager.add_score(10)
		GameManager.increment_combo()
	elif body.is_in_group("hazard"):
		take_damage(20.0)
	elif body.is_in_group("wind"):
		if body.has_method("get_wind_force"):
			wind_force += body.get_wind_force()
