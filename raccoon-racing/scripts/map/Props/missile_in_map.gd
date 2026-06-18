extends MoveObject
class_name MissileInMap

var onhitstatfun:Callable
var onhitcarfun:Callable
var petrolength:int
var petrowidth:int


func reset(x:float,y:float,r:float)->void:
      global_position=Vector2(x,y)
      rotation=r
      Update();

func Update()->void:
    pass
    
func AddPetro()->void:
    pass
    
func DoAction(action:int)->void:
    pass
