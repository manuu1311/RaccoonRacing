extends CanvasLayer
class_name PropHud

@onready var prop_box_run: AudioStreamPlayer = $PropBoxRun
var PropBoxRunTime:int
var PropId:int=-1
var showprop:bool=false
var charid:int
var itemready:bool=false
var activetween:Tween
@onready var timer: Timer = $Timer
@onready var box: Sprite2D = $Control/Visual/Box
@onready var animation_player: AnimationPlayer = $Control/Visual/AnimationPlayer
var proprunsound:AudioStream=preload("res://Assets/Sounds/2369_snd_PropBoxRun.mp3")
var propoksound:AudioStream=preload("res://Assets/Sounds/2370_snd_PropBoxOk.mp3")
@onready var propparticle: Sprite2D = $Control/propmove
@onready var propmoveplayer: AnimationPlayer = $Control/propmoveplayer
@onready var shaderplayer: AnimationPlayer = $Control/shaderplayer
@onready var icon: AnimatedSprite2D = $Control/Icon
@onready var shiny: AnimatedSprite2D = $Control/Shiny



func _ready() -> void:
	hide()
	icon.hide()
	timer.timeout.connect(RunPropBox)
	propparticle.hide()

func DeferredInit(id: int)->void:
	charid=id
	var charicon:Texture2D = load("res://Assets/Images/hud/Prop/Icons/"+str(charid)+".png")
	icon.sprite_frames.add_frame("default",charicon)

#TODO: finish implementation
func StartPropBox(runtime:float,id:int):
	PlayPropRun()
	if itemready or PropId!=-1:
		return
	show()
	PropBoxRunTime=int(runtime*1000)
	PropId=id
	icon.hide()
	if not animation_player.is_playing():
		animation_player.play("Appear")
	
func RunPropBox()->void:
	if not showprop:
		return
	PropBoxRunTime-=50
	var _loc3_: = int(PropBoxRunTime / 50);
	var _loc2_:int
	if(_loc3_ != 1 && _loc3_ != 2 && _loc3_ != 3 && _loc3_ != 4 && _loc3_ != 6 && _loc3_ != 7 && _loc3_ != 8 && _loc3_ != 10 && _loc3_ != 11 && _loc3_ != 13):
		_loc2_=randi_range(0,8)
		while(_loc2_ == icon.frame or _loc2_==PropId):
			_loc2_ = randi_range(0,8)
		icon.frame=_loc2_
	if PropBoxRunTime<=0:
		propparticle.hide()
		PlayPropOk()
		PropBoxRunTime=0
		icon.frame=PropId
		timer.stop()
		itemready=true
		return
		
func propmove(x:float,y:float)->void:
	if activetween!=null and activetween.is_valid():		
		activetween.kill()
		
	var camera:Camera2D= get_viewport().get_camera_2d()
	var pos = camera.get_viewport().get_screen_transform() * camera.get_canvas_transform() * Vector2(x,y)
	propmoveplayer.play()
	shaderplayer.play("shader")
	propparticle.show()
	propparticle.global_position = pos
	propparticle.scale = Vector2(0.5, 0.5) 
	
	# Calculate a middle peak
	var xoffset:int=randi_range(-200,200)
	var yoffset:int=randi_range(25,150)
	var mid_pos:Vector2 = pos + Vector2(xoffset,yoffset) 
	
	activetween=create_tween()

	activetween.tween_property(propparticle, "global_position", mid_pos, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	activetween.parallel().tween_property(propparticle, "scale", Vector2(1.2, 1.2), 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var fly_duration: float = 0.2

	# X-axis: Moves smoothly with a slight cubic ease
	activetween.tween_property(propparticle, "global_position:x", icon.global_position.x, fly_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# Y-axis: Starts slow, then aggressively snaps into the UI (creates the hook/curve effect)
	activetween.parallel().tween_property(propparticle, "global_position:y", icon.global_position.y, fly_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		

	# Scale down as it hits the icon
	activetween.parallel().tween_property(propparticle, "scale", Vector2(0.1, 0.1), fly_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	activetween.chain().tween_callback(OnShaderFinished)

func OnShaderFinished()->void:
	propparticle.hide()
	if itemready:
		return
	showprop=true
	timer.start()
	icon.show()
	shiny.play()

func PlayPropRun()->void:
	prop_box_run.stream=proprunsound
	prop_box_run.play()
	
func PlayPropOk()->void:
	prop_box_run.stop()
	prop_box_run.stream=propoksound
	prop_box_run.play()
	
	
func PropUsed()->void:
	PropId=-1
	itemready=false
	hide()
	icon.hide()
	propparticle.hide()
