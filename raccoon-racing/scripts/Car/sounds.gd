extends Node2D
class_name CarSounds

#Variables
var soundsVolume: float = 1.0
# Panning: -1.0 is full left, 1.0 is full right
var sounds_pen: float = 0.0
var prevSpeed: Vector2=Vector2.ZERO
@onready var car: Car = $".."

#all sound players
@onready var car_fast_speed: AudioStreamPlayer2D = $CarFastSpeed
@onready var car_run_speed: AudioStreamPlayer2D = $CarRunSpeed
@onready var car_add_speed: AudioStreamPlayer2D = $CarAddSpeed
@onready var car_lost_speed: AudioStreamPlayer2D = $CarLostSpeed
@onready var car_bs: AudioStreamPlayer2D = $CarBs
@onready var car_small_bs: AudioStreamPlayer2D = $CarSmallBs
@onready var hc_add_speed: AudioStreamPlayer2D = $HCAddSpeed
@onready var hc_run: AudioStreamPlayer2D = $HCRun
@onready var hc_lost_speed: AudioStreamPlayer2D = $HCLostSpeed
@onready var car_stop: AudioStreamPlayer2D = $CarStop
@onready var jump: AudioStreamPlayer2D = $Jump
@onready var hc_jump: AudioStreamPlayer2D = $HCJump
@onready var hc_bump: AudioStreamPlayer2D = $HCBump
@onready var car_bump: AudioStreamPlayer2D = $CarBump
@onready var missile: AudioStreamPlayer2D = $Missile
@onready var hc_end_jump: AudioStreamPlayer2D = $HCEndJump
@onready var car_jump_end: AudioStreamPlayer2D = $CarJumpEnd
@onready var bomb: AudioStreamPlayer2D = $bomb
@onready var shield: AudioStreamPlayer2D = $Shield
@onready var petro: AudioStreamPlayer2D = $Petro
@onready var be_sleep: AudioStreamPlayer2D = $BeSleep
@onready var bedump: AudioStreamPlayer2D = $Bedump
@onready var dog_s: AudioStreamPlayer2D = $dogS
@onready var panda_s: AudioStreamPlayer2D = $PandaS
@onready var panda_ss: AudioStreamPlayer2D = $PandaSs
@onready var mine: AudioStreamPlayer2D = $mine
@onready var cat_s: AudioStreamPlayer2D = $catS
@onready var bear_s: AudioStreamPlayer2D = $BearS
@onready var ice: AudioStreamPlayer2D = $Ice
@onready var use_sleep: AudioStreamPlayer2D = $useSleep
@onready var oil: AudioStreamPlayer2D = $oil
@onready var get_prop: AudioStreamPlayer2D = $GetProp

var sounds:Array[AudioStreamPlayer]=[]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hc_add_speed.finished.connect(_on_hc_add_speed_finished)


func PopulateSounds()->void:
	for child in get_children():
		if child is AudioStreamPlayer2D:
			sounds.append(child)
			if car == GameData.FocusCar:
				# Replace with a non-spatial player
				var flat := AudioStreamPlayer.new()
				flat.stream = child.stream
				flat.volume_db = child.volume_db
				flat.bus = child.bus
				flat.autoplay = child.autoplay
				flat.name = child.name + "_flat"
				add_child(flat)
				child.queue_free()
				sounds.append(flat)
			else:
				sounds.append(child)
				

func Loopsounds()->void:
	var speedScalar:float = car.speed.length() / 16;
	var speedOffset:float=0;
	if(not car.isHovercraft()):
		if(car_fast_speed.playing and car_fast_speed.get_playback_position() < 0.4):
			return 
		if(speedScalar > 0.8):
			car_add_speed.stop()
			car_lost_speed.stop()
			if not car_run_speed.is_playing():
				car_run_speed.play()
		else:
			if car.speed.length() <= 3.0:
				speedOffset = 0.0
			else:
				speedOffset = 0.05
			#is accelerating?
			if(car.speed.length() > prevSpeed.length() - speedOffset):
				speedScalar = car_add_speed.stream.get_length()*speedScalar 
				if(not car_add_speed.playing or  abs(speedScalar - car_add_speed.get_playback_position()) > car_add_speed.stream.get_length() / 5):
					#in seconds
					car_add_speed.play(speedScalar)
					car_run_speed.stop()
					car_lost_speed.stop()
			#decelerating
			else:
				speedScalar=car_lost_speed.stream.get_length()*speedScalar
				if (not car_lost_speed.playing or abs(speedScalar-(car_add_speed.stream.get_length()-car_lost_speed.get_playback_position()))>car_add_speed.stream.get_length()/5):
					car_lost_speed.play((car_add_speed.stream.get_length()-speedScalar))
					car_run_speed.stop()
					car_add_speed.stop()
		prevSpeed = car.speed


func playHCRunSound()->void:
	hc_lost_speed.stop()
	if hc_add_speed.playing or hc_run.playing:
		return
	hc_add_speed.play()
#once finished accelerating: run sound
func _on_hc_add_speed_finished()->void:
	if not hc_run.is_playing():
		hc_run.play()

func GetProp()->void:
	get_prop.play()
	
func stopHCRunSound()->void:
	if(hc_add_speed.playing or hc_run.playing):
		hc_add_speed.stop()
		hc_run.stop()
		hc_lost_speed.play()


func playFastSound()->void:
	if not car.isHovercraft():
		car_add_speed.stop()
		car_lost_speed.stop()
		car_run_speed.stop()
		if not car_fast_speed.playing:
			car_fast_speed.play()
		 

func playTurnBsSound(type:int)->void:
	if(not car.isHovercraft()):
		if(type == 0):
			if not car_bs.playing:
				car_bs.play()
		elif(type == 1):
			if not car_small_bs.playing:
				car_small_bs.play()

func playBsSound()->void:
	if not car.isHovercraft():
		if not car_stop.playing:
			car_stop.play()


func playAddSpeedSound()->void:
	if not car_add_speed.playing:
		car_add_speed.play()


func playJumpSound()->void:
	if not jump.playing:
		jump.play()


func playHCJumpSound()->void:
	if(car.isHovercraft()):
		if not hc_jump.playing:
			hc_jump.play()


func playbumpsound()->void:
	if(car.isHovercraft()):
		if not hc_bump.playing:
			hc_bump.play()
	else:
		if not car_bump.playing:
			car_bump.play()

func playMissileSound()->void:
	missile.play()
	
func playHCEndJumpSound()->void:
	if(car.isHovercraft()):
		if hc_end_jump.playing:
			hc_end_jump.play()
	else:
		if car_jump_end.playing:
			car_jump_end.play()
			
func playerBombSound()->void:
	bomb.play()

func playShieldSound()->void:
	shield.play()
	
func playPetroSound()->void:
	petro.play()
	
	
func playBeSleepSound()->void:
	be_sleep.play()
	
func StopBeSleepSound()->void:
	be_sleep.stop()
	
func playBedumpSound()->void:
	bedump.play()
	
func playdogSSound()->void:
	dog_s.play()
	
func StopdogSSound()->void:
	dog_s.stop()

func playPandaSSound()->void:
	panda_s.stop()
	panda_ss.stop()
	panda_ss.play()
	panda_s.play()
	
func StopPandaSSound()->void:
	panda_s.stop()
	panda_ss.stop()
	
func playmineSound()->void:
	mine.play()

func playCatSSound()->void:
	cat_s.play()
	
func playBearSSound()->void:
	bear_s.play()
	
func playIceSound()->void:
	ice.play()
	
func playuseSleepSound()->void:
	use_sleep.play()
	
func playoilSound()->void:
	oil.play()
