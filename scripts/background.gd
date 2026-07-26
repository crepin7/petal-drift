extends Node2D
## Scrolling starfield background with a gradient sky.
##
## Three layers of stars at different speeds for parallax.
## Warm gradient at the bottom, dark space at the top.

var stars_layer1: Array = []  # Slow, dim
var stars_layer2: Array = []  # Medium
var stars_layer3: Array = []  # Fast, bright occasional twinkle
var screen_size: Vector2
var scroll_speed: float = 30.0

@onready var gradient_rect: ColorRect = $GradientRect

func _ready() -> void:
	screen_size = get_viewport_rect().size
	_generate_stars(60, stars_layer1, 0.3, 0.5)
	_generate_stars(40, stars_layer2, 0.6, 0.8)
	_generate_stars(20, stars_layer3, 1.0, 1.5)
	
	# Background gradient
	if gradient_rect:
		gradient_rect.color = Color(0.05, 0.02, 0.1, 1.0)  # Deep space

func _process(delta: float) -> void:
	# Scroll stars downward
	_scroll_stars(delta, stars_layer1, scroll_speed * 0.3)
	_scroll_stars(delta, stars_layer2, scroll_speed * 0.7)
	_scroll_stars(delta, stars_layer3, scroll_speed * 1.2)

func _generate_stars(count: int, array: Array, min_bright: float, max_bright: float) -> void:
	for i in range(count):
		var star := {
			"pos": Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y)),
			"radius": randf_range(0.5, 2.5),
			"brightness": randf_range(min_bright, max_bright),
			"twinkle_speed": randf_range(1.0, 4.0),
			"twinkle_offset": randf_range(0, TAU)
		}
		array.append(star)

func _scroll_stars(delta: float, array: Array, speed: float) -> void:
	for star in array:
		star["pos"].y += speed * delta
		if star["pos"].y > screen_size.y + 10:
			star["pos"].y = -10
			star["pos"].x = randf_range(0, screen_size.x)

func _draw() -> void:
	# Draw the gradient manually
	var rect := Rect2(Vector2.ZERO, screen_size)
	var top_color := Color(0.02, 0.01, 0.06, 1.0)
	var bottom_color := Color(0.1, 0.03, 0.2, 1.0)
	draw_rect(rect, top_color)
	
	# Draw stars
	_draw_star_layer(stars_layer1, 1.0)
	_draw_star_layer(stars_layer2, 2.0)
	_draw_star_layer(stars_layer3, 3.0)

func _draw_star_layer(stars: Array, size_mult: float) -> void:
	for star in stars:
		var twinkle := sin(Time.get_ticks_msec() * 0.001 * star["twinkle_speed"] + star["twinkle_offset"])
		var brightness := star["brightness"] * (0.7 + 0.3 * twinkle)
		var color := Color(brightness, brightness * 0.9, brightness, brightness)
		var radius := star["radius"] * size_mult * (0.8 + 0.2 * twinkle)
		draw_circle(star["pos"], radius, color)
