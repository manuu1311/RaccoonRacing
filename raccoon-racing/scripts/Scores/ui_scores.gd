extends CanvasLayer

@onready var continuetext: Label = $Text/ContinueButton/maintext
@onready var a_ichar_1: Node2D = $Icons/AIchar1
@onready var a_ichar_2: Node2D = $Icons/AIchar2
@onready var a_ichar_3: Node2D = $Icons/AIchar3
@onready var playerchar: Node2D = $Icons/Char
@onready var lap_label: Label = $Text/LapInfo/LapLabel
@onready var racetime: Label = $Text/TimeInfo/Racetime
@onready var cuptime: Label = $Text/TimeInfo/Cuptime
@onready var continuebutton: Node2D = $Text/ContinueButton
var difftextures:Array[Texture]=[
	preload("res://Assets/Animations/Scores/down.png"),
	preload("res://Assets/Animations/Scores/up.png"),
	preload("res://Assets/Animations/Scores/same.png")
]
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
	if GameData.IsMultiplayer and not NetworkManager.is_host:
		continuebutton.hide()
	CoolTexts()
	UiOverAnimation.animated_sprite_2d.frame=0
	MusicPlayer.PlayMusic("stats")
	continuetext.add_theme_color_override("font_color",Color.WHITE)
	var positions:Array[Node2D]= [playerchar,a_ichar_1,a_ichar_2,a_ichar_3]
	var nodepositions:Array[Vector2]= [
		playerchar.position,a_ichar_1.position,
		a_ichar_2.position,a_ichar_3.position
		]
	for i:int in GameData.Ranking.size():
		var orderid:int=GameData.Ranking[i]
		var player:Player=GameData.PlayersArr[orderid]
		var gradient:Sprite2D=positions[i].get_node("gradient")
		#if player.car==GameData.FocusCar:
		if player.PlayerID==0:
			gradient.self_modulate=Color(0,0.45,0,0.36)
		else:
			gradient.self_modulate=Color(1,1,1,0.1)
		var icon:Sprite2D=positions[i].get_node("Icon")
		icon.texture=textures[player.charid] 
		var lblname:Label=positions[i].get_node("name")
		if player.name.length()<2:
			lblname.text=names[player.charid] 
		else:
			lblname.text=player.name
		var lblrank:Label=positions[i].get_node("rank")
		lblrank.text=str(i+1)
		var lblpoints:Label=positions[i].get_node("points")
		lblpoints.text=str(player.ScorePoints)
		var lblpointsadd:Label=positions[i].get_node("pointsadd")
		lblpointsadd.text=str(scorepoints[player.OrderId])
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
		tween.parallel().tween_method(func(val:int)->void: lblpointsadd.text = "+" + str(val), scorepoints[player.OrderId], 0, 0.3)

		var new_total:int = player.ScorePoints + scorepoints[player.OrderId]
		tween.parallel().tween_method(func(val:int)->void: lblpoints.text = str(val), player.ScorePoints, new_total, 0.3).set_delay(0.2)

		# 5. --- IMPACT POP & CLEAN UP ---
		tween.tween_property(lblpoints, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(lblpoints, "scale", Vector2.ONE, 0.1)

		# Reset the added score label behind the scenes
		tween.tween_callback(func()->void:
			lblpointsadd.hide()
		)
		
		#first animation over
		#add points to player
		player.ScorePoints+=scorepoints[player.OrderId]
	var oldranking:Array[int]=GameData.Ranking.duplicate()
	SortRankingArray()
	for i:int in oldranking.size():
		var orderid:int=oldranking[i]
		var player:Player=GameData.PlayersArr[orderid]
		#second animation now
		var secondtween:Tween=create_tween()
		var newrank:int=GetNewRank(player.PlayerID)
		secondtween.tween_interval(2.0)
		secondtween.tween_property(positions[i],"position",nodepositions[newrank],0.5)
		secondtween.tween_callback(func()->void:
			var lblrank:Label=positions[i].get_node("rank")
			lblrank.text=str(newrank+1)
			var diff:Sprite2D=positions[i].get_node("diff")
			if i==newrank:
				diff.texture=difftextures[2]
			elif newrank>i:
				diff.texture=difftextures[1]
			else:
				diff.texture=difftextures[0]
		)
		
	   
func CoolTexts()->void:
	lap_label.text=str(GameData.currentStep+1)+'/'+str(GameData.cupInfo[GameData.currentCup].size())
	racetime.text=GameData.format_time(GameData.CurrentRaceTime)
	cuptime.text=GameData.format_time(GameData.CurrentCupTime)
	 
	
func GetNewRank(id:int)->int:
	for i in range(GameData.Ranking.size()):
		if GameData.Ranking[i]==id:
			return i
	return -1

func SortRankingArray()->void:
	GameData.Ranking.sort_custom(func(a:int, b:int)->bool:
		var score_a:int = GameData.PlayersArr[a].ScorePoints
		var score_b:int = GameData.PlayersArr[b].ScorePoints
		return score_a > score_b
	)

func _on_continue_mouse_entered() -> void:
	continuetext.add_theme_color_override("font_color",Color.YELLOW)


func _on_continue_mouse_exited() -> void:
	continuetext.add_theme_color_override("font_color",Color.WHITE)

@rpc('authority','call_local','reliable')
func NextScene()->void:
	GameData.currentStep+=1
	if GameData.currentStep<GameData.cupInfo[GameData.currentCup].size():
		MusicPlayer.stop()
		GameData.UpdateInfo()
		GameData.OrderInfo=GameData.Ranking.duplicate()
		for i in GameData.Ranking.size():
			var orderid:int=GameData.Ranking[i]
			GameData.PlayersArr[orderid].OrderId=orderid
		get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_loading_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_cup_won.tscn")


func _on_continue_pressed() -> void:
	NextScene.rpc()
	
	
