extends Node2D
class_name CarSounds

#Variables
var soundsVolume: float = 1.0
# Panning: -1.0 is full left, 1.0 is full right
var sounds_pen: float = 0.0 
var prevSpeed: Vector2=Vector2.ZERO
@onready var car: Car = $".."
@onready var player: Player = $"../Player"

#all sound players
@onready var car_fast_speed: AudioStreamPlayer = $CarFastSpeed
@onready var car_run_speed: AudioStreamPlayer = $CarRunSpeed
@onready var car_add_speed: AudioStreamPlayer = $CarAddSpeed
@onready var car_lost_speed: AudioStreamPlayer = $CarLostSpeed
@onready var car_bs: AudioStreamPlayer = $CarBs
@onready var car_small_bs: AudioStreamPlayer = $CarSmallBs
@onready var hc_add_speed: AudioStreamPlayer = $HCAddSpeed
@onready var hc_run: AudioStreamPlayer = $HCRun
@onready var hc_lost_speed: AudioStreamPlayer = $HCLostSpeed
@onready var car_stop: AudioStreamPlayer = $CarStop
@onready var jump: AudioStreamPlayer = $Jump
@onready var hc_jump: AudioStreamPlayer = $HCJump
@onready var hc_bump: AudioStreamPlayer = $HCBump
@onready var car_bump: AudioStreamPlayer = $CarBump
@onready var missile: AudioStreamPlayer = $Missile
@onready var hc_end_jump: AudioStreamPlayer = $HCEndJump
@onready var car_jump_end: AudioStreamPlayer = $CarJumpEnd
@onready var bomb: AudioStreamPlayer = $bomb
@onready var shield: AudioStreamPlayer = $Shield
@onready var petro: AudioStreamPlayer = $Petro
@onready var be_sleep: AudioStreamPlayer = $BeSleep
@onready var bedump: AudioStreamPlayer = $Bedump
@onready var dog_s: AudioStreamPlayer = $dogS
@onready var panda_s: AudioStreamPlayer = $PandaS
@onready var panda_ss: AudioStreamPlayer = $PandaSs
@onready var mine: AudioStreamPlayer = $mine
@onready var cat_s: AudioStreamPlayer = $catS
@onready var bear_s: AudioStreamPlayer = $BearS
@onready var ice: AudioStreamPlayer = $Ice
@onready var use_sleep: AudioStreamPlayer = $useSleep
@onready var oil: AudioStreamPlayer = $oil

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    hc_add_speed.finished.connect(_on_hc_add_speed_finished)


func Loopsounds()->void:
    #distance between car and focus car (player)
    var dx: float = global_position.x - Game.fcsCar.global_position.x
    var dy: float = global_position.y - Game.fcsCar.global_position.y
    var dist_sqr: float = (dx * dx) + (dy * dy)
    soundsVolume = (160000.0 - dist_sqr) / 1600.0
    if(dist_sqr > 1000):
        soundsVolume -= 20
    if(soundsVolume < 0):
        soundsVolume = 0;
        return 
    #prevent sounds from being too loud if there are many cars around
    var totalVolume:float = 0;
    for id in len(Game.players):
        var otherplayer: Player= Game.players[id]
        if otherplayer.playerID==player.playerID:
            continue 
        #totalVolume += Game.players[id].sounds.soundsVolume;
    
    if(totalVolume > 150):
        soundsVolume *= 150 / totalVolume;
    #Calculate Panning 
    var as2_pen: float = ((dx - 400.0) / 4.0) + 100.0
    as2_pen = clamp(as2_pen, -100.0, 100.0)
    #normalise between -1 and 1
    sounds_pen = as2_pen / 100.0
    #apply new settings
    apply_global_sound_settings()
    #this.sounds.changeAllSoundVolumeAndPan(this.soundsVolume,this.soundsPen);
    #pitch and state calculation
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
                    car_add_speed.play(speedScalar / 1000.0)
                    car_run_speed.stop()
                    car_lost_speed.stop()
            #decelerating
            else:
                speedScalar=car_lost_speed.stream.get_length()*speedScalar
                if (not car_lost_speed.playing or abs(speedScalar-car_add_speed.stream.get_length()-car_lost_speed.get_playback_position())>car_add_speed.stream.get_length()):
                    car_lost_speed.play((car_add_speed.stream.get_length()-speedScalar)/1000)
                car_run_speed.stop()
                car_add_speed.stop()
        prevSpeed = car.speed

func apply_global_sound_settings() -> void:
    # Flash volume went up to ~100+. Godot uses decibels (0 dB is full, -60 dB is silent)
    # This is a basic conversion curve. 
    var db_volume:float = linear_to_db(clamp(soundsVolume / 100.0, 0.0, 1.0))
    
    var all_sounds:Array = [car_run_speed, car_add_speed, car_lost_speed, car_fast_speed, car_bs, car_small_bs, hc_add_speed, hc_run, hc_lost_speed]
    for snd in all_sounds:
        if snd:
            snd.volume_db = db_volume
            #TODO: create more buses, one for each car, and replace the first idx
    var panner = AudioServer.get_bus_effect(0, 0) as AudioEffectPanner
    panner.pan = sounds_pen

func playHCRunSound()->void:
    hc_lost_speed.stop()
    if hc_add_speed.playing or hc_run.playing:
        return
    hc_add_speed.play()
#once finished accelerating: run sound
func _on_hc_add_speed_finished()->void:
    if not hc_run.is_playing():
        hc_run.play()
        
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


func playAddSpeedSound():
    if not car_add_speed.playing:
        car_add_speed.play()


func playJumpSound():
    if not jump.playing:
        jump.play()


func playHCJumpSound():
      if(car.isHovercraft()):
        if not hc_jump.playing:
            hc_jump.play()


func playbumpsound():
      if(car.isHovercraft()):
        if not hc_bump.playing:
            hc_bump.play()
      else:
        if not car_bump.playing:
            car_bump.play()

func playMissileSound():
    missile.play()
    
func playHCEndJumpSound():
      if(car.isHovercraft()):
        if hc_end_jump.playing:
            hc_end_jump.play()
      else:
        if car_jump_end.playing:
            car_jump_end.play()
            
func playerBombSound():
   bomb.play()

func playShieldSound():
    shield.play()
    
func playPetroSound():
    petro.play()
    
    
func playBeSleepSound():
    be_sleep.play()
    
func StopBeSleepSound():
    be_sleep.stop()
    
func playBedumpSound():
    bedump.play()
    
func playdogSSound():
    dog_s.play()
    
func StopdogSSound():
   dog_s.stop()

func playPandaSSound():
    panda_s.stop()
    panda_ss.stop()
    panda_ss.play()
    panda_s.play()
    
func StopPandaSSound():
    panda_s.stop()
    panda_ss.stop()
    
func playmineSound():
    mine.play()

func playCatSSound():
    cat_s.play()
    
func playBearSSound():
    bear_s.play()
    
func playIceSound():
    ice.play()
    
func playuseSleepSound():
    use_sleep.play()
    
func playoilSound():
    oil.play()
