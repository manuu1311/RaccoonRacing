extends Node
class_name VibrationHandler

@export var friction_min := 60.0
@export var friction_max := 80.0
@export var friction_weak_max := 0.35

@export var bs_amount := 0.5
@export var bs_fade_speed := 2.5        # per second, once bs ends

@export var bsex_strong_max := 1.0
@export var bsex_fade_per_point := 0.02 # more bsex -> longer fade
@export var bsex_fade_min := 0.3

@export var bump_weak_pulse := 0.3
@export var bump_strong_pulse := 0.3
@export var bump_fade_speed := 6.0      # fast decay, feels like a "tap"
@export var wall_bump_max_lost_speed:=35
@export var kart_bump_max_lost_speed:=25

@export var send_hz := 25.0

var car: Car
var device := 0

var friction_val := 0.0
var bs_val := 0.0
var bsex_val := 0.0
var bsex_last_trigger := 0
var bump_weak_val := 0.0
var bump_strong_val := 0.0

var _send_accum := 0.0
var _last_weak := -1.0
var _last_strong := -1.0

func _ready() -> void:
	set_process(false)

func RegisterCar(fcscar: Car) -> void:
	if GameData.VibrationMultiplier<0.5:
		return
	var joys := Input.get_connected_joypads()
	if joys.is_empty():
		return
	car = fcscar
	device = joys[0] # TODO: real player->device mapping
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	car.WallBump.connect(OnWallBump)
	car.KartBump.connect(OnKartBump)
	await ready
	set_process(true)

func _process(delta: float) -> void:
	_update_friction()
	_update_bs(delta)
	_update_bsex(delta)
	_update_bumps(delta)
	_send(delta)

func _update_friction() -> void:
	if car.bs:
		friction_val = 0.0 # bs channel takes over once you're actually sliding
		return
	friction_val = clamp(remap(car.friction, friction_min, friction_max, 0.0, friction_weak_max), 0.0, friction_weak_max)

func _update_bs(delta: float) -> void:
	if car.bs:
		bs_val = bs_amount  # scale this by spin speed too, if you have it
	else:
		bs_val = max(bs_val - bs_fade_speed * delta, 0.0)

func _update_bsex(delta: float) -> void:
	if car.bsex > 0 and car.bsex != bsex_last_trigger:
		bsex_val = max(bsex_val, clamp(car.bsex / 100.0, 0.0, 1.0) * bsex_strong_max)
		bsex_last_trigger = car.bsex
	elif car.bsex <= 0:
		bsex_last_trigger = 0
	var fade_time: float = max(bsex_last_trigger * bsex_fade_per_point, bsex_fade_min)
	bsex_val = max(bsex_val - delta / fade_time, 0.0)

func _update_bumps(delta: float) -> void:
	bump_weak_val = max(bump_weak_val - bump_fade_speed * delta, 0.0)
	bump_strong_val = max(bump_strong_val - bump_fade_speed * delta, 0.0)

func OnWallBump(knockback: float) -> void:
	knockback/=wall_bump_max_lost_speed
	bump_weak_val = max(bump_weak_val, clamp(knockback, 0.0, 1.0) * bump_weak_pulse)

func OnKartBump(knockback: float) -> void:
	knockback/=kart_bump_max_lost_speed
	bump_strong_val = max(bump_strong_val, clamp(knockback, 0.0, 1.0) * bump_strong_pulse)
	bump_weak_val = max(bump_weak_val, clamp(knockback, 0.0, 1.0) * bump_weak_pulse * 0.5)

func _send(delta: float) -> void:
	var weak: float = clamp(friction_val + bump_weak_val, 0.0, 1.0)
	var strong: float = clamp(max(bs_val, bsex_val) + bump_strong_val, 0.0, 1.0)

	_send_accum += delta
	var interval := 1.0 / send_hz
	if _send_accum < interval:
		return
	_send_accum = 0.0

	if is_equal_approx(weak, _last_weak) and is_equal_approx(strong, _last_strong):
		return
	_last_weak = weak
	_last_strong = strong

	if weak <= 0.001 and strong <= 0.001:
		Input.stop_joy_vibration(device)
	else:
		Input.start_joy_vibration(device, weak, strong, interval * 2.0)


func _on_joy_connection_changed(changed_device: int, connected: bool) -> void:
	if changed_device != device:
		return
	if connected:
		set_process(true)
	else:
		set_process(false)
		Input.stop_joy_vibration(device)
