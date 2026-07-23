extends CarController
class_name AICarController

var aiplayer:AIPlayer

func _init(playerinst:Player) -> void:
    aiplayer=playerinst as AIPlayer
    super(playerinst)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input()->void:
    return
    var inputArr:Array[bool]=aiplayer.AutoInput()
    forward=inputArr[0]
    brake=inputArr[1]
    left=inputArr[2]
    right=inputArr[3]
    special=aiplayer.AutoUseProp()
