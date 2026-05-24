extends Control
class_name DifficultyButtons

var locks: Array[bool]=[1,1,1]
#greyed out icon transform
var r_g_b: float = 102.0 / 256.0
var btns: Array[TextureRect]
var txts: Array[Label]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btns=[$EasyBTN,$NormalBTN,$HardBTN]
	txts=[$EasyInfotext,$NormalInfotext,$HardInfotext]

func updateLocks(id: int):
	#was the race won before?
	var racewon=GameData.cupWon[id]
	for i in range(3):
		if racewon>=i:
			locks[i]=0
			greyin(btns[i])
			txts[i].hide()
		else:
			locks[i]=1
			greyout(btns[i])
			txts[i].show()


func _on_diff_mouse_entered(diff: int) -> void:
	#if difficulty is not available: return
	if locks[diff-1]:
		return
	#else: play sound, resize icons
	ButtonSounds.PlaySound('hover')
	for i in range(3):
		if diff-1==i:
			btns[i].scale=Vector2(1.2,1.2)
			btns[i].position-=btns[i].size*0.1
			txts[i].scale=Vector2(1.2,1.2)
			txts[i].position-=txts[i].size*0.1
			
		else:
			btns[i].scale=Vector2(0.8,0.8)
			btns[i].position+=btns[i].size*0.1
			txts[i].scale=Vector2(0.8,0.8)
			txts[i].position+=txts[i].size*0.1



func _on_diff_mouse_exited(diff: int) -> void:
	if locks[diff-1]:
		return
	for i in range(3):
		if diff-1==i:
			btns[i].scale=Vector2(1,1)
			btns[i].position+=btns[i].size*0.1
			txts[i].scale=Vector2(1,1)
			txts[i].position+=txts[i].size*0.1
		else:
			btns[i].scale=Vector2(1,1)
			btns[i].position-=btns[i].size*0.1
			txts[i].scale=Vector2(1,1)
			txts[i].position-=txts[i].size*0.1

func greyout(rect: TextureRect):
	rect.modulate = Color(r_g_b, r_g_b, r_g_b, 1)
func greyin(rect: TextureRect):
	rect.modulate = Color(1,1,1, 1)
