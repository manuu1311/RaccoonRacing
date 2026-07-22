extends Node2D
class_name ShrinkInMap

@onready var line_glow: Line2D = $LineGlow   # width 14, red #FF2200 alpha 128
@onready var line_mid:  Line2D = $LineMid    # width 6,  orange #FF8800 alpha 200
@onready var line_core: Line2D = $LineCore   # width 2,  white #FFFFFF alpha 255

@onready var start_sprite: Sprite2D  = $Start
@onready var end_sprite:   Sprite2D  = $End
@onready var start_light:  PointLight2D = $Start/PointLight2D
@onready var end_light:    PointLight2D = $End/PointLight2D

var attacker: Node2D
var victim:   Node2D

const STEPS := 10

func _ready() -> void:
	var tex := _make_radial_texture(64)
	start_light.texture = tex
	end_light.texture   = tex

func _make_radial_texture(size: int) -> ImageTexture:
	var img    := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var dist  := Vector2(x, y).distance_to(center) / radius
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha          # quadratic falloff = softer edge
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func setup(from_node: Node2D, to_node: Node2D, duration: float) -> void:
	attacker = from_node
	victim   = to_node
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _process(_delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(victim):
		queue_free()
		return

	var start_pos := attacker.global_position
	var end_pos   := victim.global_position
	var diff      := end_pos - start_pos
	var length    := diff.length()

	# Safety: nodes on top of each other
	if length < 1.0:
		return

	start_sprite.global_position = start_pos
	end_sprite.global_position   = end_pos

	var along      := diff / length
	var perp       := Vector2(-along.y, along.x)
	var dist_scale := minf(absf(100.0 / length), 1.0)

	# Build shared point list (lightning jitter, regenerated every frame)
	var pts: Array[Vector2] = []
	pts.append(to_local(start_pos))

	for i in range(1, STEPS):
		var sx   := 1.0 if randi() % 2 == 0 else -1.0
		var sy   := 1.0 if randi() % 2 == 0 else -1.0
		var xj   := sx * (randi() % 15) * ((STEPS - i) * 0.5) * dist_scale
		var yp   := i * length / STEPS + (randi() % 15) * sy
		pts.append(to_local(start_pos + along * yp + perp * xj))

	pts.append(to_local(end_pos))

	# Apply to all three layers
	for ln:Line2D in [line_glow, line_mid, line_core]:
		ln.clear_points()
		for p in pts:
			ln.add_point(p)

	# Pulse the endpoint lights
	var pulse := randf_range(0.8, 1.3)
	start_sprite.scale = Vector2.ONE * pulse
	end_sprite.scale   = Vector2.ONE * pulse
	start_light.energy = pulse * 1.5
	end_light.energy   = pulse * 1.5
