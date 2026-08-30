extends Node2D
class_name CarAgent

#region export variables
@export var car:Car
@export var sensors:CustomRaycastObs
## offset to account for car shape
@export var offset:=30
@export_group("Debug Settings")
@export var debug_rays:bool=true
@export var debug_wall_color:Color=Color.RED
@export var debug_jumpwall_color:Color=Color.YELLOW
@export var debug_empty_color:Color=Color.GREEN
@export var debug_ray_width:int=2

#endregion

var sensor_output:PackedFloat32Array
var _max_observed:float=0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	sensor_output=sensors.get_observation()
	if debug_rays:
		queue_redraw()

func _normalize_dist(dist: float, max_dist: float) -> float:
	var clamped_dist:float = clampf(dist-offset, 0.0, max_dist)
	var log_0_to_1: float = log(1.0 + clamped_dist) / log(1.0 + max_dist)
	
	# Remap from [0.0, 1.0] to [-1.0, 1.0]
	return (log_0_to_1 * 2.0) - 1.0


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12
	
	for i in range(0, sensor_output.size(), 5):
		var is_colliding: float = sensor_output[i]
		var hit_distance: float = sensor_output[i + 1]
		var ray_length: float = sensor_output[i + 2]
		var collision_type: float = sensor_output[i + 3]
		var ray_angle: float = sensor_output[i + 4]-90
		var processed_distance:float=0.0

		var dir: Vector2 = Vector2.RIGHT.rotated(car.global_rotation + deg_to_rad(ray_angle))
		
		var end_point: Vector2
		var text_val: String
		var line_color: Color
		
		if is_colliding < 0.5:
			if collision_type >= 0.5:
				# skip non-colliding jumpwalls
				continue
			end_point = car.position + dir * ray_length
			line_color = debug_empty_color
			text_val = ''
		else:
			end_point = car.position + dir * hit_distance
			line_color = debug_jumpwall_color if collision_type >= 0.5 else debug_wall_color
			#text_val = "%.1f" % (hit_distance/ray_length)
			processed_distance=_normalize_dist(hit_distance,ray_length)
			text_val = "%.1f" % (processed_distance)
			if processed_distance<_max_observed:
				_max_observed=processed_distance
			
		# Draw the ray line
		draw_line(car.position, end_point, line_color, debug_ray_width)
		
		var text_position: Vector2 = end_point + dir * 8.0
		draw_string(font, text_position, text_val, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, line_color)
