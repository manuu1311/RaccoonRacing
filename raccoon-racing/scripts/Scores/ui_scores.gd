extends CanvasLayer

@onready var continuetext: Label = $Text/ContinueButton/maintext
@onready var a_ichar_1: Node2D = $Icons/AIchar1
@onready var a_ichar_2: Node2D = $Icons/AIchar2
@onready var a_ichar_3: Node2D = $Icons/AIchar3
@onready var playerchar: Node2D = $Icons/Char
var textures:Array[Texture]=[
	null,
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
	]
var names:Array[String]=[
	"",
	"Rocko","Vixen","Mambo","Pingo","Hudson","Banzai"
]
var scorepoints:Array[int]=[10,8,6,4]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#TODO: prova
	GameData.PopulatePlayers()
	GameData.FocusCar=GameData.PlayersArr[0].car
	#FINISH TODO
	MusicPlayer.PlayMusic("stats")
	continuetext.add_theme_color_override("font_color",Color.WHITE)
	var positions:Array[Node2D]= [playerchar,a_ichar_1,a_ichar_2,a_ichar_3]
	for orderid:int in GameData.OrderInfo:
		var player:Player=GameData.PlayersArr[orderid]
		var gradient:Sprite2D=positions[orderid].get_node("gradient")
		#if player.car==GameData.FocusCar:
		if player.PlayerID==0:
			gradient.self_modulate=Color(0,0.45,0,0.36)
		else:
			gradient.self_modulate=Color(1,1,1,0.25)
		var icon:Sprite2D=positions[orderid].get_node("Icon")
		icon.texture=textures[player.charid] 
		var lblname:Label=positions[orderid].get_node("name")
		lblname.text=names[player.charid] 
		var lblrank:Label=positions[orderid].get_node("rank")
		lblrank.text=str(orderid+1)
		var lblpoints:Label=positions[orderid].get_node("points")
		lblpoints.text=str(player.ScorePoints)
		#add points to player
		player.ScorePoints+=scorepoints[orderid]
		var lblpointsadd:Label=positions[orderid].get_node("pointsadd")
		lblpointsadd.text=str(scorepoints[orderid])
		lblpointsadd.self_modulate=Color(1,1,1,0)
		
		#cool animation
		var tween: Tween = create_tween().set_parallel(false)
		tween.tween_interval(1.0)

		# 1. Fade in the added points label (Original speed)
		lblpointsadd.show()
		tween.tween_property(lblpointsadd, "self_modulate:a", 1.0, 0.3)
		tween.tween_property(lblpointsadd, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(lblpointsadd, "scale", Vector2.ONE, 0.1)
		# 2. Your original 0.5-second comfortable pause
		tween.tween_interval(0.5)

		# 3. THE FLIGHT (Original 0.3-second duration)
		tween.tween_property(lblpointsadd, "position", lblpoints.position, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(lblpointsadd, "modulate:a", 0.0, 0.3)

		# 4. THE COUNTING (Starts instantly alongside the flight!)
		# By using .parallel(), these start counting the EXACT millisecond the label begins moving
		tween.parallel().tween_method(func(val): lblpointsadd.text = "+" + str(val), scorepoints[orderid], 0, 0.3)

		var new_total = player.ScorePoints + scorepoints[orderid]
		tween.parallel().tween_method(func(val): lblpoints.text = str(val), player.ScorePoints, new_total, 0.3).set_delay(0.2)

		# 5. --- IMPACT POP & CLEAN UP ---
		tween.tween_property(lblpoints, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(lblpoints, "scale", Vector2.ONE, 0.1)

		# Reset the added score label behind the scenes
		tween.tween_callback(func():
			lblpointsadd.hide()
		)
	

func _on_continue_mouse_entered() -> void:
	continuetext.add_theme_color_override("font_color",Color.YELLOW)


func _on_continue_mouse_exited() -> void:
	continuetext.add_theme_color_override("font_color",Color.WHITE)


func _on_continue_pressed() -> void:
	pass
