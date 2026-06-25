extends Node
class_name HUDManager

@onready var prop_hud: PropHud = $PropHud
@onready var speed_hud: SpeedHud = $SpeedHud
@onready var char_hud: CharHud = $CharHud
@onready var lbl321: Label = $"321/321"
@onready var lbl321_player: AnimationPlayer = $"321/321Player"
var FocusCar:Car
# Called when the node enters the scene tree for the first time.

func Hide()->void:
	prop_hud.hide()
	speed_hud.hide()
	char_hud.hide()

func setup() -> void:
	prop_hud.hide()
	speed_hud.show()
	char_hud.show()
	char_hud.setup() 
	lbl321.self_modulate=Color.TRANSPARENT


func SetCar(car:Car)->void:
	FocusCar=car
	prop_hud.DeferredInit(car.player.charid)
	prop_hud.prop_visible.connect(car.player.ResetUse)
	speed_hud.SetCar(FocusCar)

func PropItemReady()->bool:
	return prop_hud.itemready

func PropUsed(id:int)->void:
	prop_hud.PropUsed(id)

func propmove(x:float,y:float)->void:
	prop_hud.propmove(x,y)
func StartPropBox(runtime:float,id:int)->void:
	prop_hud.show()
	prop_hud.StartPropBox(runtime,id)

func updatelap()->void:
	speed_hud.on_lap_completed()

func play_overtake(overtaker:int, overtaken:int)->void:
	char_hud.play_overtake(overtaker,overtaken)

func ShowMessage(message:String)->void:
	lbl321.text=message
	lbl321_player.play("Messageshow")
