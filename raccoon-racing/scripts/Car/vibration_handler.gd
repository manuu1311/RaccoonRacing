extends Node
class_name VibrationHandler

# --- pre-trigger buildup (the "about to lose it" ramp, before bs actually fires) ---
# Stays on the weak motor only, and stays soft until you're genuinely close
# to the trigger point — see the cubic curve in _update_pretrigger below.
@export var pretrigger_weak_mix := 0.22
@export var pretrigger_release_speed := 4.0  # per second; how fast it lets go once friction drops

# --- bs (active spinout) ---
@export var bs_amount := 0.5               # max strength at the top of the intensity range
@export var bs_speed_reference := 20.0     # speed.length() that reads as "full intensity" spin
@export var bs_fade_speed := 2.5           # per second, once bs ends
@export var bs_weak_bleed := 0.3           # how much bs shows up on the weak motor too

# --- bsex (movement-stop stun, e.g. missile/mine) ---
@export var bsex_strong_max := 1.0
@export var bsex_reference := 100.0  # car.bsex value that reads as "full intensity" hit

# --- bumps (wall/kart impacts) ---
@export var bump_weak_pulse := 0.3
@export var bump_strong_pulse := 0.3
@export var bump_fade_speed := 6.0
@export var wall_bump_max_lost_speed := 35
@export var kart_bump_max_lost_speed := 25

var car: Car
var device := 0

var pretrigger_val := 0.0
var bs_val := 0.0
var bsex_val := 0.0
var bsex_last_trigger := 0
var bsex_peak := 0
var bump_weak_val := 0.0
var bump_strong_val := 0.0

var _last_weak := -1.0
var _last_strong := -1.0

###mobile variables
var ismobile: bool = false
##give precedence to joypad
var hasjoypad: bool = false
var _mobile_timer: float = 0.0
@export var mobile_haptic_hz: int = 15

func _ready() -> void:
	set_process(false)

func RegisterCar(fcscar: Car) -> void:
	if GameData.VibrationMultiplier < 0.5:
		return
	car = fcscar
	if OS.has_feature('android'):
		ismobile = true
	var joys := Input.get_connected_joypads()
	if not joys.is_empty():
		hasjoypad = true
		if Game.IsSplitScreen:
			if car.player.input_device_type == 'Joypad':
				device = joys[car.player.input_device_id]
			else:
				return
		else:
			device = joys[0]
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	elif not ismobile:
		return
	car.WallBump.connect(OnWallBump)
	car.KartBump.connect(OnKartBump)
	set_process(true)

func _process(delta: float) -> void:
	_update_pretrigger(delta)
	_update_bs(delta)
	_update_bsex()
	_update_bumps(delta)
	_send(delta)

# Ramps up only when friction AND speed are BOTH closing in on the thresholds
# that actually trigger bs (car.bsWheelLength / car.bsSpeed), instead of
# reacting to friction alone. Below bsClearSpeed, bs literally can't trigger
# (see Car.Forward), so there's nothing to anticipate.
#
# car.friction itself settles slowly in the sim (the slide-correction force
# pulls it down gradually), so tracking it 1:1 on the way down made the
# rumble feel like it lingered after you let off the turn. Instead: snap up
# instantly to match rising friction (attack), but on the way down, decay on
# our own fixed timer rather than waiting for friction to physically settle
# (release) -- it can only get less "ahead" of the true value, never behind.
func _update_pretrigger(delta: float) -> void:
	var target := 0.0
	if not car.bs and car.speed.length() > car.bsClearSpeed:
		var friction_norm: float = clamp(car.friction / car.bsWheelLength, 0.0, 1.0)
		var speed_norm: float = clamp(car.speed.length() / car.bsSpeed, 0.0, 1.0)
		var imminence: float = friction_norm * speed_norm
		target = imminence * imminence * imminence
	if target >= pretrigger_val:
		pretrigger_val = target
	else:
		pretrigger_val = max(0.0, pretrigger_val - pretrigger_release_speed * delta)

# Intensity now scales with how fast you're actually spinning (between
# car.bsClearSpeed, where bs releases, and bs_speed_reference, a tunable
# "this is a violent spin" ceiling), so it hits hard on impact and tapers
# naturally as drag bleeds your speed off — instead of a flat 0.5 the
# whole time.
func _update_bs(delta: float) -> void:
	if car.bs:
		var speed_norm: float = clamp(
			remap(car.speed.length(), car.bsClearSpeed, bs_speed_reference, 0.0, 1.0),
			0.0, 1.0
		)
		bs_val = speed_norm * bs_amount
	else:
		bs_val = max(bs_val - bs_fade_speed * delta, 0.0)

# car.bsex IS the remaining stun duration (it decrements once per frame in
# Car.ProcessFX until you regain control), so instead of decaying the
# rumble on a separately-tuned timer -- which could easily finish before or
# after the actual stun depending on fps or hit size -- we derive intensity
# directly as a fraction of remaining-vs-peak. That guarantees bsex_val
# reaches 0 exactly when car.bsex reaches 0: the rumble runs for the whole
# stun, no more, no less. sqrt eases it so it stays present through most of
# the stun and only tapers right at the very end, near when you regain control.
func _update_bsex() -> void:
	if car.bsex > bsex_last_trigger:
		bsex_peak = car.bsex  # new/stacked hit -- this is our 100% reference point
	bsex_last_trigger = car.bsex
	if car.bsex <= 0 or bsex_peak <= 0:
		bsex_val = 0.0
		return
	var remaining_norm: float = clamp(float(car.bsex) / float(bsex_peak), 0.0, 1.0)
	var magnitude_norm: float = clamp(float(bsex_peak) / bsex_reference, 0.0, 1.0)
	bsex_val = sqrt(remaining_norm) * magnitude_norm * bsex_strong_max

func _update_bumps(delta: float) -> void:
	bump_weak_val = max(bump_weak_val - bump_fade_speed * delta, 0.0)
	bump_strong_val = max(bump_strong_val - bump_fade_speed * delta, 0.0)

func OnWallBump(knockback: float) -> void:
	knockback /= wall_bump_max_lost_speed
	bump_weak_val = max(bump_weak_val, clamp(knockback, 0.0, 1.0) * bump_weak_pulse)

func OnKartBump(knockback: float) -> void:
	knockback /= kart_bump_max_lost_speed
	bump_strong_val = max(bump_strong_val, clamp(knockback, 0.0, 1.0) * bump_strong_pulse)
	bump_weak_val = max(bump_weak_val, clamp(knockback, 0.0, 1.0) * bump_weak_pulse * 0.5)

func _send(delta: float) -> void:
	var weak: float = clamp(
		pretrigger_val * pretrigger_weak_mix + bump_weak_val + bs_val * bs_weak_bleed,
		0.0, 1.0
	)
	# Strong is reserved for things that actually happened: an active spinout,
	# a stun, or an impact. The buildup never touches this channel, so
	# ordinary turning can't read as "strong" no matter how close you get.
	var strong: float = clamp(max(bs_val, bsex_val) + bump_strong_val, 0.0, 1.0)

	if ismobile and not hasjoypad:
		_send_mobile(delta, weak, strong)
		return

	# Sent once per _process call instead of throttled to a separate Hz —
	# 25hz didn't divide evenly into a 35fps process rate, so the old
	# accumulator alternated between firing every 1 and every 2 frames,
	# which itself added a faint stutter to the signal. Duration is tied
	# to delta so it always covers to the next update regardless of fps.
	if is_equal_approx(weak, _last_weak) and is_equal_approx(strong, _last_strong):
		return
	_last_weak = weak
	_last_strong = strong

	if weak <= 0.001 and strong <= 0.001:
		Input.stop_joy_vibration(device)
	else:
		Input.start_joy_vibration(device, weak, strong, delta * 2.0)

func _on_joy_connection_changed(changed_device: int, connected: bool) -> void:
	if changed_device != device:
		return
	if connected:
		set_process(true)
	else:
		set_process(false)
		Input.stop_joy_vibration(device)

func _send_mobile(delta: float, weak: float, strong: float) -> void:
	var combined_intensity: float = max(weak, strong) * GameData.VibrationMultiplier
	if combined_intensity <= 0.05:
		return
	_mobile_timer += delta
	var interval := 1.0 / mobile_haptic_hz
	if _mobile_timer >= interval:
		_mobile_timer = 0.0
		var duration_ms := int(interval * 1000.0)
		Input.vibrate_handheld(duration_ms, combined_intensity)

func _trigger_mobile_impulse(duration_ms: int, intensity: float) -> void:
	var final_amplitude := intensity * GameData.VibrationMultiplier
	if final_amplitude > 0.05:
		Input.vibrate_handheld(duration_ms, final_amplitude)
