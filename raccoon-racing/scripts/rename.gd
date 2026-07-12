@tool
extends EditorScript

# Configure these in the Inspector before running the script!
@export var base_name: String = "jumpwall"
@export var total_nodes: int = 4
@export var starting_index: int = 0
var swappos=false

func _run() -> void:
	var parent = get_editor_interface().get_selection().get_selected_nodes()
	if parent.is_empty():
		print("Please select the parent node in the Scene dock first!")
		return
	
	var parent_node = parent[0]
	var max_index = starting_index + total_nodes - 1
	
	# 1. Gather the nodes dynamically into a strict sequential list
	var target_nodes: Array[Node] = []
	for i in range(starting_index, starting_index + total_nodes):
		var target_name = base_name + str(i)
		var node = parent_node.get_node_or_null(target_name)
		if node:
			target_nodes.append(node)
	
	if target_nodes.size() != total_nodes:
		print("Aborting: Found ", target_nodes.size(), " nodes, but expected ", total_nodes)
		return

	# 2. Swap Positions 
	# We use 'i' as the array index (0 to half_count) to safely swap outer edge pairs.
	if swappos:
		var half_count = total_nodes / 2
		for i in range(half_count):
			var opposite_array_index = total_nodes - 1 - i
			var node_a = target_nodes[i]
			var node_b = target_nodes[opposite_array_index]
			
			if node_a is Node2D and node_b is Node2D:
				var temp_pos = node_a.position
				node_a.position = node_b.position
				node_b.position = temp_pos
			elif node_a is Node3D and node_b is Node3D:
				var temp_pos = node_a.position
				node_a.position = node_b.position
				node_b.position = temp_pos

		print("Positions successfully swapped for ", total_nodes, " nodes.")

	# 3. Rename to TEMPORARY names to prevent duplicate name clashes
	for i in range(total_nodes):
		target_nodes[i].name = "TEMP_swap_holder_" + str(i)

	# 4. Apply the final reversed names
	for i in range(total_nodes):
		var new_index = max_index - i
		target_nodes[i].name = base_name + str(new_index)

	print("Finished! Successfully reversed positions and names.")
