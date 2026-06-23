extends Node
class_name HUDManager

@onready var prop_hud: PropHud = $PropHud
@onready var speed_hud: SpeedHud = $SpeedHud
@onready var char_hud: CharHud = $CharHud
var FocusCar:Car
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func SetCar(car:Car)->void:
	FocusCar=car
	prop_hud.DeferredInit(car.player.charid)
	prop_hud.prop_visible.connect(car.player.ResetUse)
	speed_hud.SetCar(car)

func PropItemReady()->bool:
	return prop_hud.itemready

func PropUsed(id:int)->void:
	prop_hud.PropUsed(id)

func propmove(x:float,y:float)->void:
	prop_hud.propmove(x,y)
func StartPropBox(runtime:float,id:int)->void:
	prop_hud.StartPropBox(runtime,id)

func updatelap()->void:
	speed_hud.on_lap_completed()
