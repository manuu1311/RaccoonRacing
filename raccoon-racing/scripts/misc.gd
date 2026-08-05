@tool
extends EditorScript

func _run() -> void:
	print(InputMap.action_get_events('Brake'))
