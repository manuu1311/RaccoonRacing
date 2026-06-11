extends Node
class_name Ed

#TODO: static array typing
var AddSurfaceArr:Array[EdLine]
var LengthX:float
var LengthY:float
var SurfaceArr:Array[Array]
var minX:float
var minY:float
var newSurfaceArr:Array[EdLine]

func _init() -> void:
    AddSurfaceArr=[]
    SurfaceArr=[]
    newSurfaceArr=[]

func AddLine(x1:float,y1:float,x2:float,y2:float)->EdLine:
    var _loc2_:EdLine = EdLine.new(x1,y1,x2,y2);
    AddSurfaceArr.append(_loc2_);
    newSurfaceArr.append(_loc2_);
    return _loc2_;

func AddRectangle(x:float,y:float,width:float,height:float,angle:float)->EdRectangle:
    var _loc2_:EdRectangle = EdRectangle.new(x,y,width,height,angle);
    AddSurfaceArr.append(_loc2_);
    newSurfaceArr.append(_loc2_);
    return _loc2_;


func ReTidyFace()->void:   
    var _loc10_:float = AddSurfaceArr[0].maxX;
    var _loc9_:float = AddSurfaceArr[0].maxY;
    minX = AddSurfaceArr[0].minX;
    minY = AddSurfaceArr[0].minY;
    var _loc2_:int = 1;
    while(_loc2_ < len(AddSurfaceArr)):
        if(AddSurfaceArr[_loc2_].maxX > _loc10_):
            _loc10_ = AddSurfaceArr[_loc2_].maxX;
        if(AddSurfaceArr[_loc2_].minX < minX):
            minX = AddSurfaceArr[_loc2_].minX;
        if(AddSurfaceArr[_loc2_].maxY > _loc9_):
            _loc9_ = AddSurfaceArr[_loc2_].maxY;
        if(AddSurfaceArr[_loc2_].minY < minY):
            minY = AddSurfaceArr[_loc2_].minY;
        _loc2_ = _loc2_ + 1;
    LengthX = (_loc10_ - minX) / int(sqrt(len(AddSurfaceArr)));
    LengthY = (_loc9_ - minY) / int(sqrt(len(AddSurfaceArr)));
    
    
    SurfaceArr=[]
    _loc2_ = 0;
    var _loc3_:int
    while(_loc2_ <= int(sqrt(len(AddSurfaceArr)))):
        SurfaceArr.append([])
        _loc3_ = 0;
        #TODO: is it a flash error, < instead of <=? flash is more forgiving on arrays
        while(_loc3_ <= int(sqrt(len(AddSurfaceArr)))):
            SurfaceArr[_loc2_].append([])
            _loc3_ = _loc3_ + 1;
        _loc2_ = _loc2_ + 1;
    _loc2_ = 0;
    var _loc8_:int
    var _loc7_:int
    var _loc6_:int
    var _loc5_:int
    var _loc4_:int
    while(_loc2_ < len(AddSurfaceArr)):
        _loc8_ = int((AddSurfaceArr[_loc2_].minX - minX) / LengthX);
        _loc7_ = int((AddSurfaceArr[_loc2_].maxX - minX) / LengthX);
        _loc6_ = int((AddSurfaceArr[_loc2_].minY - minY) / LengthY);
        _loc5_ = int((AddSurfaceArr[_loc2_].maxY - minY) / LengthY);
        _loc3_ = _loc8_;
        while(_loc3_ <= _loc7_):
            _loc4_ = _loc6_;
            while(_loc4_ <= _loc5_):
                SurfaceArr[_loc3_][_loc4_].append(AddSurfaceArr[_loc2_]);
                _loc4_ = _loc4_ + 1;
            _loc3_ = _loc3_ + 1;
        _loc2_ = _loc2_ + 1;
    newSurfaceArr = []


#find which shape is touched at point.x,point.y
func getHitFace(point:Vector2)->EdLine:
    #additional safety check, flash is more forgiving: if arrays are empty, return null
    #if length is 0, arrays not initialized->prevent division by zero
    if LengthX==0 or LengthY==0:
        return null
    var cellx:int = int((point.x - minX) / LengthX);
    var celly:int = int((point.y - minY) / LengthY);
    var i:int = 0

    if len(SurfaceArr)<=cellx or len(SurfaceArr[cellx])<=celly:
        return null
    while(i < len(SurfaceArr[cellx][celly])):
        if(SurfaceArr[cellx][celly][i].HitTest(point.x,point.y)):
            return SurfaceArr[cellx][celly][i];
        i+=1
    i = 0;
    while(i < len(newSurfaceArr)):
        if(newSurfaceArr[i].HitTest(point.x,point.y)):
            return newSurfaceArr[i];
        i+=1
    return null;

#TODO: is it really needed, or is it just flash memory cleaning?
func del_ed(ed_id: int) -> void:
    # 1. Clean out the 2D grid cells safely
    for col in SurfaceArr:
        for cell_list in col:
            for i in range(cell_list.size() - 1, -1, -1):
                if cell_list[i].id == ed_id:
                    cell_list.remove_at(i)
                    
    # 2. Clean out tracking arrays safely by looping backwards
    for i in range(AddSurfaceArr.size() - 1, -1, -1):
        if AddSurfaceArr[i].id == ed_id:
            AddSurfaceArr.remove_at(i)
            
    for i in range(newSurfaceArr.size() - 1, -1, -1):
        if newSurfaceArr[i].id == ed_id:
            newSurfaceArr.remove_at(i)

#visualize, for debugging
func draw_debug_geometry(overlay_node: Node2D) -> void:
    if not overlay_node:
        return
        
    # We pass the drawing commands directly to a Node2D canvas
    for shape in AddSurfaceArr:
        # Define a bright color for your debug lines (e.g., semi-transparent neon green)
        var debug_color := Color(0.0, 1.0, 0.0, 1.0) 
        
        if shape is EdLine:
            
            var direction = (shape.p2 - shape.p1).normalized()
            # Get the perpendicular vector for thickness (rotated 90 degrees counter-clockwise)
            var perpendicular = Vector2(-direction.y, direction.x) 
            var thickness_vector = perpendicular * shape.LineWidth

            # Calculate the 4 corners based on the EDLine definition
            var corner1 = shape.p1
            var corner2 = shape.p2
            var corner3 = shape.p2 + thickness_vector
            var corner4 = shape.p1 + thickness_vector

            var polygon_points = PackedVector2Array([corner1, corner2, corner3, corner4, corner1])

            # Draw it as an outline
            overlay_node.draw_polyline(polygon_points, debug_color, 2.0)
            print(shape.GetAngle())
