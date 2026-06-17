extends Player
class_name AIPlayer

func RunPropBox(x:float,y:float)->void:
	pass

func Update()->void:
	car.Update()
	prop.run()
	UpdatePoint()
	
func UpdatePoint()->void:
	pass
