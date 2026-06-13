extends Node
class_name EdLine

var id:int
var ang:float
var IsActivated:bool
var maxX:float
var maxY:float
var minX:float
var minY:float
var p1:Vector2
var p2:Vector2
var LineWidth:int=50
static var addid:int=0

func _init(x1:float,y1:float,x2:float,y2:float) -> void:
	id = addid
	addid+=1
	p1 = Vector2(x1,y1)
	p2 = Vector2(x2,y2)
	ang = rad_to_deg(atan2(y2 - y1, x2 - x1))
	IsActivated = true
	var _loc4_ = Vector2(LineWidth,0);
	_loc4_=_loc4_.rotated(deg_to_rad(ang-90));
	var _loc3_:Array[Vector2] = [
		p1,
		p2,
		Vector2(p2.x + _loc4_.x, p2.y + _loc4_.y),
		Vector2(p1.x + _loc4_.x, p1.y + _loc4_.y)
	]
	minX = _loc3_[0].x;
	maxX = _loc3_[0].x;
	minY = _loc3_[0].y;
	maxY = _loc3_[0].y;
	for i in range(1, _loc3_.size()):
		var pt = _loc3_[i]
		if pt.x < self.minX: self.minX = pt.x
		if pt.x > self.maxX: self.maxX = pt.x
		if pt.y < self.minY: self.minY = pt.y
		if pt.y > self.maxY: self.maxY = pt.y

func HitTest(x:float,y:float)->bool:
	if(not IsActivated):
		return false;
	if(x > maxX || x < minX || y > maxY || y < minY):
		return false;
	var _loc2_:Vector2 = Vector2(x - p1.x,y - p1.y);
	_loc2_=_loc2_.rotated(deg_to_rad(-ang));
	var _loc3_:Vector2 = Vector2(p1.x + _loc2_.x,p1.y + _loc2_.y);
	_loc2_ = Vector2(p2.x - p1.x,p2.y - p1.y);
	_loc2_=_loc2_.rotated(deg_to_rad(-ang));
	var _loc4_:Vector2 = Vector2(p1.x + _loc2_.x,p1.y + _loc2_.y);
	if(_loc3_.x > p1.x && _loc3_.x < _loc4_.x && _loc3_.y < p1.y && _loc3_.y > p1.y - LineWidth):
		return true;
	return false;
	
func ReSetLineWidth(linewidth:int)->void:
	LineWidth = linewidth
	var _loc4_:Vector2 = Vector2(linewidth,0)
	_loc4_=_loc4_.rotated(deg_to_rad(ang-90));
	var _loc3_:Array[Vector2] = [
		p1,
		p2,
		Vector2(p2.x + _loc4_.x,p2.y + _loc4_.y),
		Vector2(p1.x + _loc4_.x,p1.y + _loc4_.y)
	]
	minX = _loc3_[0].x
	maxX = _loc3_[0].x
	minY = _loc3_[0].y
	maxY = _loc3_[0].y
	var _loc2_:int = 1;
	while(_loc2_ < _loc3_.size()):
		if(_loc3_[_loc2_].x < minX):
			minX = _loc3_[_loc2_].x;
		
		if(_loc3_[_loc2_].x > maxX):
			maxX = _loc3_[_loc2_].x;

		if(_loc3_[_loc2_].y < minY):
			minY = _loc3_[_loc2_].y;
		if(_loc3_[_loc2_].y > maxY):
			maxY = _loc3_[_loc2_].y;
		_loc2_ = _loc2_ + 1;
	

func GetAngle()->float:
	return ang
	
	
func getId()->int:
	return id
