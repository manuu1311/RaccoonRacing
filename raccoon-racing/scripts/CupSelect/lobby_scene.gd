extends Control
class_name LobbyScene

var difficulties:Array
@export var names:Array[String]
var textures:Array[Texture]=[
	preload("res://icon.svg"),
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
	]
@export var rects:Array[TextureRect]
@export var labels:Array[LineEdit]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateIconsNames()


func UpdateIconsNames()->void:
	#online players connected
	for i in range(GameData.PlayersArr.size()):
		var player:Player=GameData.PlayersArr[i]
		rects[i].texture=textures[player.charid]
		labels[i].text=player.OnlineName
		if player.PlayerID!=NetworkManager.PlayerID:
			labels[i].editable=false
		else:
			labels[i].editable=true
	#bots
	for i in range(GameData.PlayersArr.size(),4,1):
		rects[i].texture=textures[0]
		labels[i].text=names[i]
		labels[i].editable=false
		
		
		
