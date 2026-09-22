@tool
extends EditorScript

func _run() -> void:
	var vectorized:=PackedFloat32Array()
	vectorized.resize(10)
	print(vectorized)
