extends CanvasLayer
class_name CharHud

@onready var vbox: VBoxContainer = $VBoxContainer
var textures:Array[Texture]=[
	null,
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
]
var active_tweens: Dictionary = {}  # TextureRect -> Tween
var pending_moves: Dictionary = {}  # TextureRect -> destination_index
@onready var char_1: IconController = $VBoxContainer/Char1
@onready var char_2: IconController = $VBoxContainer/Char2
@onready var char_3: IconController = $VBoxContainer/Char3
@onready var char_4: IconController = $VBoxContainer/Char4
var chars:Array[IconController]

func setup() -> void:
	chars=[char_1,char_2,char_3,char_4]
	for i in range(GameData.PlayersArr.size()):
		var rect:IconController=vbox.get_child(i) as IconController
		rect.texture=textures[GameData.PlayersArr[GameData.OrderInfo[i]].charid]
		rect.setup(GameData.PlayersArr[GameData.OrderInfo[i]].PlayerID)
		
func SleepEffect(playerid:int)->void:
	for icon:IconController in chars:
		if icon.playerid==playerid:
			icon.PlaySleep()
	
func StopSleep()->void:
	for icon:IconController in chars:
		icon.StopSleep()
	
## Kills a tween group and immediately commits their pending move_child,
## so the VBox order always reflects logical reality before the next call reads it.
func _snap_tween_group(tween: Tween) -> void:
	var nodes: Array[TextureRect] = []
	for node: TextureRect in active_tweens.keys():
		if active_tweens[node] == tween:
			nodes.append(node)

	tween.kill()

	for node in nodes:
		node.top_level = false
		node.scale = Vector2.ONE
		active_tweens.erase(node)

	# Commit the logical reorder so indices are correct for the next call
	for node in nodes:
		if pending_moves.has(node):
			vbox.move_child(node, pending_moves[node])
			pending_moves.erase(node)


func play_overtake(overtaker_index: int, overtaken_index: int) -> void:
	if overtaker_index < 0 or overtaker_index >= vbox.get_child_count(): return
	if overtaken_index < 0 or overtaken_index >= vbox.get_child_count(): return
	if overtaker_index == overtaken_index: return

	# --- STEP 1: Snap any in-flight animations at the target indices FIRST ---
	# This ensures VBox child order is correct before we read it.
	var tweens_to_snap: Array[Tween] = []
	for node: TextureRect in active_tweens.keys():
		if node.get_index() == overtaker_index or node.get_index() == overtaken_index:
			var t: Tween = active_tweens[node]
			if not tweens_to_snap.has(t):
				tweens_to_snap.append(t)
	for t in tweens_to_snap:
		_snap_tween_group(t)

	# --- STEP 2: Now indices are reliable — grab nodes ---
	var overtaker: TextureRect = vbox.get_child(overtaker_index) as TextureRect
	var overtaken: TextureRect = vbox.get_child(overtaken_index) as TextureRect
	if not overtaker or not overtaken or overtaker == overtaken: return

	# --- STEP 3: Cache positions and sizes while still in VBox layout ---
	var overtaker_pos: Vector2 = overtaker.global_position
	var overtaken_pos: Vector2 = overtaken.global_position

	# --- STEP 4: Record logical destination so snapping works if interrupted ---
	pending_moves[overtaker] = overtaken_index
	pending_moves[overtaken] = overtaker_index

	# --- STEP 5: Pull nodes out of VBox layout ---
	overtaker.top_level = true
	overtaken.top_level = true
	overtaker.scale = Vector2(0.35,0.35)
	overtaken.scale = Vector2(0.35,0.35)
	overtaker.global_position = overtaker_pos
	overtaken.global_position = overtaken_pos

	# --- STEP 6: Animate ---
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tweens[overtaker] = tween
	active_tweens[overtaken] = tween

	var duration: float = 0.4
	var half: float = duration * 0.5

	tween.tween_property(overtaker, "global_position:y", overtaken_pos.y, duration)
	tween.tween_property(overtaker, "global_position:x", overtaker_pos.x + 40.0, half)
	tween.tween_property(overtaker, "global_position:x", overtaker_pos.x, half).set_delay(half)

	tween.tween_property(overtaken, "global_position:y", overtaker_pos.y, duration)
	tween.tween_property(overtaken, "global_position:x", overtaken_pos.x - 30.0, half)
	tween.tween_property(overtaken, "global_position:x", overtaken_pos.x, half).set_delay(half)

	# --- STEP 7: Restore nodes and commit logical reorder ---
	tween.chain().tween_callback(func() -> void:
		overtaker.top_level = false
		overtaken.top_level = false
		overtaker.scale = Vector2.ONE
		overtaken.scale = Vector2.ONE
		vbox.move_child(overtaker, overtaken_index)
		vbox.move_child(overtaken, overtaker_index)
		active_tweens.erase(overtaker)
		active_tweens.erase(overtaken)
		pending_moves.erase(overtaker)
		pending_moves.erase(overtaken)
		reconcile_positions()
	)
	
func reconcile_positions() -> void:
	if not active_tweens.is_empty():
		return  # don't fight in-flight animations

	for icon: IconController in chars:
		var pid: int = icon.playerid
		var expected_index: int = GameData.OrderInfo.find(pid)
		# adjust lookup to however playerid->orderid actually maps in your data
		if expected_index != -1 and icon.get_index() != expected_index:
			push_warning("Icon for player %d drifted: at %d, expected %d" % [pid, icon.get_index(), expected_index])
			vbox.move_child(icon, expected_index)
	
