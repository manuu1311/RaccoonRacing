@tool
extends EditorPlugin

var dock: Control
var name_prefix_field: LineEdit
var parent_path_field: LineEdit
var counter_starts_field: LineEdit
var counter := 1

# Tell Godot we want to intercept inputs in the 2D editor
func _handles(object: Object) -> bool:
    return true

func _enter_tree():
    dock = VBoxContainer.new()
    dock.name = "Place Marker"

    dock.add_child(_label("Shift+Click to place Marker2D"))

    dock.add_child(_label("Name prefix:"))
    name_prefix_field = LineEdit.new()
    name_prefix_field.text = "Point"
    dock.add_child(name_prefix_field)

    dock.add_child(_label("Parent node path (optional):"))
    parent_path_field = LineEdit.new()
    parent_path_field.placeholder_text = "e.g. Markers or Level/Waypoints"
    dock.add_child(parent_path_field)

    dock.add_child(_label("Counter starts:"))
    counter_starts_field = LineEdit.new()
    counter_starts_field.placeholder_text = "Counter n"
    dock.add_child(counter_starts_field)
    
    var reset_btn = Button.new()
    reset_btn.text = "Reset counter to n"
    reset_btn.pressed.connect(func(): counter = int(counter_starts_field.text))
    dock.add_child(reset_btn)

    add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

func _exit_tree():
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()

func _forward_canvas_gui_input(event: InputEvent) -> bool:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed:
            var root = get_editor_interface().get_edited_scene_root()
            if not root:
                return false

            # Resolve parent
            var parent: Node = root
            var path = parent_path_field.text.strip_edges()
            if path != "":
                var found = root.get_node_or_null(path)
                if found:
                    parent = found
                else:
                    printerr("PlaceMarker: node not found at path '%s', using scene root" % path)

            # --- FIX 1: Get the correct 2D world position ---
            var editor_viewport = get_editor_interface().get_editor_viewport_2d()
            var canvas_xform = editor_viewport.global_canvas_transform
            var world_pos = canvas_xform.affine_inverse() * event.position

            var marker = Marker2D.new()

            # Convert world position into local coordinates for the parent node
            if parent is Node2D:
                marker.position = parent.to_local(world_pos)
            elif parent is Control:
                marker.position = parent.get_global_transform().affine_inverse() * world_pos
            else:
                marker.position = world_pos

            marker.name = "%s%d" % [name_prefix_field.text, counter]
            counter += 1

            # --- FIX 2: Correct Undo/Redo sequence ---
            # Node MUST be added to the tree before you can set its owner
            var undo = get_undo_redo()
            undo.create_action("Place Marker2D")
            undo.add_do_method(parent, "add_child", marker)
            undo.add_do_reference(marker) # Keeps reference alive in undo history
            undo.add_do_method(marker, "set_owner", root)
            undo.add_undo_method(parent, "remove_child", marker)
            undo.commit_action()
            

            return true # Consume event
            
    return false

func _label(txt: String) -> Label:
    var l = Label.new()
    l.text = txt
    return l
