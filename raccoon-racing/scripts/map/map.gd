extends Node2D
class_name Map

#flag to draw collisions, debug 
@export var drawcollision:bool=false
var ed:Ed
var edm:Ed
var edevent:Ed
var Events:Array[EventInMap]
var AddspeedNum: int
var BsNum:int
var GrassNum:int
var GroupGrassGroupNum:int
var GroupGrassNum:int
var JumpNum:int
var JumpWallGroupNum:int
var JumpWallNum:int
var LapsTotal:int
var LinePointArr:Array[int]
var PointNum:int
var Points:Array[Vector2]
var PropPointArr:Array[int]
var StartPosArr:Array[Marker2D]
var PropboxNum:int
#changed from original one
var IsHovercraft:bool
var WallGroupNum:int
var WallNum:int
var WanPointArr:Array[int]
var ScaledTimes:float
var TileWidth:int= 0
var TileHeight:int = 0
var TileNum:int = 0
var CupMapi:int = 0
var CupMapj = 0
var MapBy:int = 10000
var MapTy:int = -10000
var MapLx:int = -10000
var MapRx:int = 10000
var MoO:int = 10
var GlideGratingNum:float
var RollGratingNum:float
var GrassGratingNum:float
var Wallspring:float
#array containing group walls and their relative walls
var WallsArr:Array[Array]
@onready var top2: Node2D = $Visuals/Ground/Top2
#jump wall points
var canBeJumpWall:Array[int]
# Called when the node enters the scene tree for the first time.
#offsets useful for minimap
var offsethc: Vector2
var offsetcar:Vector2
var PointsPath:String

func _ready() -> void:
    if GameData.current_vehicle==GameData.VehicleType.CAR:
        IsHovercraft=false
        #hide top2
        top2.hide()
        PointsPath='PointsCar'
    else:
        IsHovercraft=true
        top2.show()
        PointsPath='PointsHC'

func InitMap()->void:
    CupMapj=0
    StartCupMap(2)
    InitWalls()
    InitGrass()
    InitPoints()
    InitEventInMap()
    InitStartPos()
    #debug collisions
    if drawcollision:
        modulate=Color(1,1,1,0.5)
        queue_redraw()
    

func InitStartPos()->void:
    var newmarker:Marker2D
    var id:int=0
    newmarker=get_node_or_null(PointsPath+'/Flags/StartPos'+str(id))
    while newmarker!=null:
        StartPosArr.append(newmarker)
        id+=1
        newmarker=get_node_or_null(PointsPath+'/Flags/StartPos'+str(id))

func _draw() -> void:
    ed.draw_debug_geometry(self)


func InitWalls()->void:
    InitNormalWall()
    InitJumpWall()
    ed.ReTidyFace()


func InitNormalWall()->void:
    var currentwall:Marker2D
    var firstwall:Marker2D
    var nextwall:Marker2D
    var newwallid:int=0
    for igroupnum:int in range(WallGroupNum):
        firstwall=null
        var wallid:int = 0;
        while(wallid < WallNum):
            var markerpath:String=PointsPath+"/Walls"+str(igroupnum)+"/wall"
            currentwall= get_node_or_null(markerpath+str(wallid)) as Marker2D
            if(currentwall==null):
                wallid += 1
            else:
                if(firstwall == null):
                    firstwall = currentwall
                newwallid = wallid + 1
                while(newwallid < WallNum):
                    nextwall = get_node_or_null(markerpath+str(newwallid)) as Marker2D
                    if(nextwall!=null):
                        ed.AddLine(
                            currentwall.global_position.x,
                            currentwall.global_position.y,
                            nextwall.global_position.x,
                            nextwall.global_position.y
                            )
                        wallid = newwallid
                        break
                        
                    newwallid = newwallid + 1
                    
                if(wallid != newwallid):
                    ed.AddLine(
                        currentwall.global_position.x,
                        currentwall.global_position.y,
                        firstwall.global_position.x,
                        firstwall.global_position.y
                        );
                    break


func InitJumpWall()->void:
    canBeJumpWall = []
    var _loc7_:int = 0;
    var _loc6_:Marker2D
    var _loc4_:int
    var _loc2_;
    var _loc3_;
    var _loc5_:Marker2D
    while(_loc7_ < JumpWallGroupNum):
        _loc6_ = null;
        _loc4_ = 0;
        while(_loc4_ < JumpWallNum):
            var markerpath:String=PointsPath+"/Jumpwalls"+str(_loc7_)+"/jumpwall"
            _loc2_ = get_node_or_null(markerpath+str(_loc4_)) as Marker2D
            if(_loc2_==null):
                _loc4_ = _loc4_ + 1
            else:
                if(_loc6_ == null):
                    _loc6_ = _loc2_
                _loc3_ = _loc4_ + 1;
                while(_loc3_ < JumpWallNum):
                    _loc5_= get_node_or_null(markerpath+str(_loc3_)) as Marker2D
                    if(_loc5_!=null):
                        AddJumpEdLine(
                            _loc2_.global_position.x,
                            _loc2_.global_position.y,
                            _loc5_.global_position.x,
                            _loc5_.global_position.y
                            )
                        _loc4_ = _loc3_
                        break
                    _loc3_ = _loc3_ + 1;
                if(_loc4_ != _loc3_):
                    AddJumpEdLine(
                            _loc2_.global_position.x,
                            _loc2_.global_position.y,
                            _loc6_.global_position.x,
                            _loc6_.global_position.y
                            )
                    break;
        _loc7_ = _loc7_ + 1;

func AddJumpEdLine(x1:float,y1:float,x2:float,y2:float)->void:
    var _loc2_:EdLine = ed.AddLine(x1,y1,x2,y2)
    _loc2_.ReSetLineWidth(10)
    canBeJumpWall.append(_loc2_.getId()) 
   
#TODO: double check if it is correct 
func InitGrass() -> void:
    #added safety check, godot is stricter than flash
    if GrassNum<1:
        return
    var group_idx: int = 0
    var first_grass: Marker2D
    var grass_idx: int
    var current: Marker2D
    var next: Marker2D
    var next_idx: int

    while group_idx < GroupGrassGroupNum:
        first_grass = null
        grass_idx = 0

        while grass_idx < GroupGrassNum:
            var marker_path := PointsPath+"/GroupGrass" + str(group_idx) + "/GroupGrass"
            current = get_node_or_null(marker_path + str(grass_idx)) as Marker2D

            if current == null:
                grass_idx += 1
            else:
                if first_grass == null:
                    first_grass = current

                next_idx = grass_idx + 1

                while next_idx < GroupGrassNum:
                    next = get_node_or_null(marker_path + str(next_idx)) as Marker2D

                    if next != null:
                        edm.AddLine(
                            current.global_position.x,
                            current.global_position.y,
                            next.global_position.x,
                            next.global_position.y
                        )

                        grass_idx = next_idx
                        # current.queue_free()
                        break

                    next_idx += 1

                if grass_idx != next_idx:
                    edm.AddLine(
                        current.global_position.x,
                        current.global_position.y,
                        first_grass.global_position.x,
                        first_grass.global_position.y
                    )

                    # current.queue_free()
                    break

        group_idx += 1

    group_idx = 0

    while group_idx < GrassNum:
        var grass = get_node_or_null(
            PointsPath+"/Grass" + str(group_idx)
        ) as Node2D

        if grass == null:
            break

        var rotation_deg = grass.rotation_degrees

        grass.rotation_degrees = 0

        edm.AddRectangle(
            grass.global_position.x,
            grass.global_position.y,
            grass.scale.x * grass.get_rect().size.x if grass.has_method("get_rect") else grass.size.x,
            grass.scale.y * grass.get_rect().size.y if grass.has_method("get_rect") else grass.size.y,
            rotation_deg
        )

        # grass.queue_free()

        group_idx += 1

    edm.ReTidyFace()
    
func InitPoints()->void:
    Points = []
    var ipoint:int = 0
    var point:Marker2D
    while(ipoint < PointNum):
        point = get_node_or_null(PointsPath+"/Points/"+str(ipoint))
        if(point!=null):
            Points.append(point.global_position)
        ipoint +=1

    
func InitEventInMap()->void:
    return
    Events = []
    var _loc3_:int;
    var _loc2_:Marker2D;
    var _loc4_:float;
    _loc3_ = 0;
    while(_loc3_ < PropboxNum):
        _loc2_=get_node_or_null(PointsPath+'/Propbox'+str(_loc3_)) as Marker2D
        #if(_loc2_==null):
            #break;
        #_loc4_ = _loc2_.rotation;
        #_loc2_._rotation = 0;
        ##Events.append()
        ##this.Events.push(new as.EventsInMap.PropInMap(this.PropMc,this,_loc2_._x,_loc2_._y,_loc2_._width,_loc2_._height,_loc4_));
        #_loc2_.swapDepths(20000);
        #_loc2_.removeMovieClip();
        #_loc3_ = _loc3_ + 1;
    #_loc3_ = 0;
    #while(_loc3_ < this.JumpNum):
        #_loc2_ = this.ViewDmc.detector["jump" + _loc3_];
        #if(!_loc2_):
            #break;
        #_loc4_ = _loc2_._rotation;
        #_loc2_._rotation = 0;
        ##this.Events.push(new as.EventsInMap.JumpInMap(this.PropMc,this,_loc2_._x,_loc2_._y,_loc2_._width,_loc2_._height,_loc4_));
        #_loc2_.swapDepths(20000);
        #_loc2_.removeMovieClip();
        #_loc3_ = _loc3_ + 1;
    #_loc3_ = 0;
    #while(_loc3_ < this.AddspeedNum):
        #_loc2_ = this.ViewDmc.detector["addspeed" + _loc3_];
        #if(!_loc2_):
            #break;
        #_loc4_ = _loc2_._rotation;
        #_loc2_._rotation = 0;
        ##this.Events.push(new as.EventsInMap.AddSpeedInMap(this.PropMc,this,_loc2_._x,_loc2_._y,_loc2_._width,_loc2_._height,_loc4_));
        #_loc2_.swapDepths(20000);
        #_loc2_.removeMovieClip();
        #_loc3_ = _loc3_ + 1;
    #_loc3_ = 0;
    #while(_loc3_ < this.BsNum):
        #_loc2_ = this.ViewDmc.detector["bs" + _loc3_];
        #if(!_loc2_):
            #break;
        #_loc4_ = _loc2_._rotation;
        #_loc2_._rotation = 0;
        ##this.Events.push(new as.EventsInMap.BsInMap(this.PropMc,this,_loc2_._x,_loc2_._y,_loc2_._width,_loc2_._height,_loc4_));
        #_loc2_.swapDepths(20000);
        #_loc2_.removeMovieClip();
        #_loc3_ = _loc3_ + 1;
    #_loc3_ = 0;
    #var _loc5_;
    #while(_loc3_ < this.MoO):
        #_loc2_ = this.ViewDmc.detector["Moo" + _loc3_];
        #if(!_loc2_):
            #break
        ##_loc5_ = this.PropMc.attachMovie("map_ball" + as.GameDate.GetMapId(),"map_ball" + this._game.moveObject.length,this.PropMc.getNextHighestDepth());
        #_loc5_._x = _loc2_._x;
        #_loc5_._y = _loc2_._y;
        ##this._game.moveObject.push(new as.Prop.MoveObject(this._game,this,_loc5_,true,true));
        #_loc2_.swapDepths(20000);
        #_loc2_.removeMovieClip();
        #_loc3_ = _loc3_ + 1;
    #this.edevent.ReTidyFace();

    
@warning_ignore("narrowing_conversion")
func StartCupMap(num:int=NAN,w:int=NAN,h:int=NAN)->void:
    if(is_nan(num)):
         num = 4
    var mapsize:Vector2=GetMapSize()
    if(is_nan(w)):
        w = int(mapsize.x / num)
        
    if(is_nan(h)):
        h = int(mapsize.y / num);
    TileNum = num;
    TileWidth = w;
    TileHeight = h;
    CupMapi = 0;

func GetMapSize() -> Vector2:
    var tlp:TileMapLayer=$Visuals/Ground/Track/TileMapLayer as TileMapLayer
    var rect:Rect2i=tlp.get_used_rect()
    
    # 2. Get the size of a single tile in pixels (defined in your TileSet)
    var tile_size: Vector2 = tlp.tile_set.tile_size
    
    # 3. Calculate the raw pixel size (Total Tiles * Tile Size)
    var raw_width = rect.size.x * tile_size.x
    var raw_height = rect.size.y * tile_size.y
    
    # 4. Multiply by the node's scale to account for stretching/shrinking
    var final_width = raw_width * tlp.scale.x
    var final_height = raw_height * tlp.scale.y
    return Vector2(final_width, final_height)
    

    
#TODO: first argument in output of gethitface
func GetHitEventStatus(varx,playerid:int)->void:
    pass
