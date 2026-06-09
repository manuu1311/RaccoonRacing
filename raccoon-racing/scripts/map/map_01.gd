#extends "res://scripts/map/map.gd"
extends Map

"""
offset info: 
	car: +116,+341->3.867, 11.367
"""


func _ready() -> void:
	super()
	#exporting: 0.06666666666666666
	ScaledTimes=0.03333333333333333
	offsethc=Vector2(-0.7,0)
	offsetcar=Vector2(3.867,11.367)
