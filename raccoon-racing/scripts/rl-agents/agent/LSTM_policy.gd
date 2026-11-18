class_name LSTMPolicy
extends RefCounted

const OBS := 384
const H := 256      # encoder width
const HID := 128    # lstm size
const DEC := 128
const OUT := 8

var w0: PackedFloat32Array
var b0: PackedFloat32Array
var w1: PackedFloat32Array
var b1: PackedFloat32Array
var w_ih: PackedFloat32Array
var w_hh: PackedFloat32Array
var b_ih: PackedFloat32Array
var b_hh: PackedFloat32Array
var wd: PackedFloat32Array
var bd: PackedFloat32Array
var wa: PackedFloat32Array
var ba: PackedFloat32Array

# per-agent recurrent state
var h := PackedFloat32Array()
var c := PackedFloat32Array()

var _off := 0
const SPLITS := [3, 3, 2]

func _init() -> void:
	reset_state()

func reset_state() -> void:
	h.resize(HID); h.fill(0.0)
	c.resize(HID); c.fill(0.0)

func load_weights(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s" % path)
		return false
	var all := f.get_buffer(f.get_length()).to_float32_array()
	var expected := (H*OBS + H) + (H*H + H) + (4*HID*H) + (4*HID*HID) + 4*HID + 4*HID \
		+ (DEC*HID + DEC) + (OUT*DEC + OUT)
	if all.size() != expected:
		push_error("Size mismatch: got %d floats, expected %d" % [all.size(), expected])
		return false
	_off = 0
	w0 = _take(all, H*OBS);        b0 = _take(all, H)
	w1 = _take(all, H*H);          b1 = _take(all, H)
	w_ih = _take(all, 4*HID*H);    w_hh = _take(all, 4*HID*HID)
	b_ih = _take(all, 4*HID);      b_hh = _take(all, 4*HID)
	wd = _take(all, DEC*HID);      bd = _take(all, DEC)
	wa = _take(all, OUT*DEC);      ba = _take(all, OUT)
	return true

func _take(all: PackedFloat32Array, n: int) -> PackedFloat32Array:
	var r := all.slice(_off, _off + n)
	_off += n
	return r

static func _linear(w: PackedFloat32Array, b: PackedFloat32Array, x: PackedFloat32Array,
		out_n: int, in_n: int, relu: bool) -> PackedFloat32Array:
	var y := PackedFloat32Array()
	y.resize(out_n)
	for i in out_n:
		var s := b[i]
		var base := i * in_n
		for j in in_n:
			s += w[base + j] * x[j]
		y[i] = maxf(s, 0.0) if relu else s
	return y

## One policy step. Returns the raw 8 head outputs and updates h/c.
func step(obs: PackedFloat32Array) -> PackedFloat32Array:
	assert(obs.size() == OBS)
	var x := _linear(w0, b0, obs, H, OBS, true)
	x = _linear(w1, b1, x, H, H, true)

	# LSTM (PyTorch gate order: i, f, g, o)
	var gates := PackedFloat32Array()
	gates.resize(4 * HID)
	for k in 4 * HID:
		var s := b_ih[k] + b_hh[k]
		var bi := k * H
		for j in H:
			s += w_ih[bi + j] * x[j]
		var bh := k * HID
		for j in HID:
			s += w_hh[bh + j] * h[j]
		gates[k] = s
	for j in HID:
		var gi := _sigmoid(gates[j])
		var gf := _sigmoid(gates[HID + j])
		var gg := tanh(gates[2*HID + j])
		var go := _sigmoid(gates[3*HID + j])
		c[j] = gf * c[j] + gi * gg
		h[j] = go * tanh(c[j])

	var d := _linear(wd, bd, h, DEC, HID, true)
	return _linear(wa, ba, d, OUT, DEC, false)

static func _sigmoid(v: float) -> float:
	return 1.0 / (1.0 + exp(-v))

## Continuous case: first 4 outputs are the means, last 4 are log-std (ignored).
func act_continuous(obs: PackedFloat32Array) -> PackedFloat32Array:
	var o := step(obs)
	var a := PackedFloat32Array()
	for i in OUT / 2:
		a.append(clampf(o[i], -1.0, 1.0))
	return a

func act_from_obs(obs: PackedFloat32Array) -> Dictionary:
	var o := step(obs)
	var res := []
	var s := 0
	for n:int in SPLITS:
		var best := 0
		for i in n:
			if o[s + i] > o[s + best]:
				best = i
		res.append(best)
		s += n
	return {"throttle": res[0], "steer": res[1], "special": res[2]}

func sample_from_obs(obs: PackedFloat32Array) -> Dictionary:
	var o := step(obs)
	var res := []
	var s := 0
	for n:int in SPLITS:
		var mx := o[s]
		for i in n:
			mx = maxf(mx, o[s + i])
		var exps := []
		var total := 0.0
		for i in n:
			var e := exp(o[s + i] - mx)
			exps.append(e)
			total += e
		var r := randf() * total
		var pick := n - 1
		for i in n:
			r -= exps[i]
			if r <= 0.0:
				pick = i
				break
		res.append(pick)
		s += n
	return {"throttle": res[0], "steer": res[1], "special": res[2]}
