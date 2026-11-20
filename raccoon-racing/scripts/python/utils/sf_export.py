import json
from pathlib import Path

import numpy as np
import torch
import gymnasium as gym

from sample_factory.model.actor_critic import create_actor_critic
from sample_factory.utils.attr_dict import AttrDict

CKPT = "/mnt/dump/dump-projects/Godot/RaccoonRacing/raccoon-racing/scripts/python/train/competitive/RaccoonRacing/checkpoint_p0/checkpoint_000122976_150020096.pth"
BIN = "agent.bin"
TOL = 1e-4
STEPS = 40
RESET_AT = 20
SPLITS = [3, 3, 2]
NORM_EPS = 1e-5

OBS, H, HID, DEC, OUT = 384, 256, 128, 128, 8

# ---------- Sample Factory reference ----------
exp_dir = Path(CKPT).parent.parent
cfg = AttrDict(json.load(open(exp_dir / "config.json")))

# sanity-check the architecture assumptions
print("rnn_type:", cfg.get("rnn_type"), "| rnn_size:", cfg.get("rnn_size"),
      "| normalize_input:", cfg.get("normalize_input"))
assert cfg.get("rnn_type") == "lstm" and cfg.get("rnn_size") == HID

obs_space = gym.spaces.Dict(
    {"obs": gym.spaces.Box(-np.inf, np.inf, shape=(OBS,), dtype=np.float32)}
)
action_space = gym.spaces.Tuple(
    (gym.spaces.Discrete(3), gym.spaces.Discrete(3), gym.spaces.Discrete(2))
)

model = create_actor_critic(cfg, obs_space, action_space)
ckpt = torch.load(CKPT, map_location="cpu", weights_only=False)
model.load_state_dict(ckpt["model"])
model.eval()

# ---------- Export agent.bin ----------
sd = {k: v.detach().cpu().numpy() for k, v in model.state_dict().items()}

def get(contains, ends, shape):
    m = [k for k in sd if contains in k and k.endswith(ends) and sd[k].shape == tuple(shape)]
    assert len(m) == 1, f"expected 1 tensor ({contains}, {ends}, {shape}), got {m}"
    return sd[m[0]].astype(np.float64)

def exact(key, shape):
    assert key in sd, f"missing {key}; available: {[k for k in sd if k.startswith('encoder')]}"
    assert sd[key].shape == tuple(shape), f"{key}: {sd[key].shape} != {shape}"
    return sd[key].astype(np.float64)

p = "encoder.encoders.obs.mlp_head."
w0, b0 = exact(p + "0.weight", (H, OBS)), exact(p + "0.bias", (H,))
w1, b1 = exact(p + "2.weight", (H, H)),   exact(p + "2.bias", (H,))
w_ih = get("core", "weight_ih_l0", (4 * HID, H))
w_hh = get("core", "weight_hh_l0", (4 * HID, HID))
b_ih = get("core", "bias_ih_l0", (4 * HID,))
b_hh = get("core", "bias_hh_l0", (4 * HID,))
wd, bd = get("decoder", "weight", (DEC, HID)), get("decoder", "bias", (DEC,))
wa, ba = get("action_parameterization", "weight", (OUT, DEC)), \
         get("action_parameterization", "bias", (OUT,))

# the second encoder bias/weight lookup above is only unique if H != OBS, which holds.
# fold the observation normalizer into layer 0
mean_keys = [k for k in sd if "running_mean" in k and sd[k].shape == (OBS,)]
var_keys = [k for k in sd if "running_var" in k and sd[k].shape == (OBS,)]
if cfg.get("normalize_input", True):
    assert len(mean_keys) == 1 and len(var_keys) == 1, (mean_keys, var_keys)
    mean = sd[mean_keys[0]].astype(np.float64)
    std = np.sqrt(sd[var_keys[0]].astype(np.float64) + NORM_EPS)
    b0 = b0 - w0 @ (mean / std)
    w0 = w0 / std[None, :]
    print("folded obs normalizer into layer 0")

order = [w0, b0, w1, b1, w_ih, w_hh, b_ih, b_hh, wd, bd, wa, ba]
flat = np.concatenate([a.astype("<f4").ravel() for a in order])
flat.tofile(BIN)
print(f"wrote {BIN}: {flat.size} floats ({flat.size * 4} bytes)")

# ---------- Manual implementation (same as the GDScript) ----------
raw = np.fromfile(BIN, dtype="<f4")
expected = (H*OBS + H) + (H*H + H) + 4*HID*H + 4*HID*HID + 8*HID + (DEC*HID + DEC) + (OUT*DEC + OUT)
assert raw.size == expected, f"agent.bin has {raw.size} floats, expected {expected}"

off = 0
def take(*shape):
    global off
    n = int(np.prod(shape))
    r = raw[off:off + n].reshape(shape)
    off += n
    return r

w0, b0 = take(H, OBS), take(H)
w1, b1 = take(H, H), take(H)
w_ih, w_hh = take(4*HID, H), take(4*HID, HID)
b_ih, b_hh = take(4*HID), take(4*HID)
wd, bd = take(DEC, HID), take(DEC)
wa, ba = take(OUT, DEC), take(OUT)

def sigmoid(x):
    return 1.0 / (1.0 + np.exp(-x))

def manual_step(obs, h, c):
    x = np.maximum(w0 @ obs + b0, 0)
    x = np.maximum(w1 @ x + b1, 0)
    g = w_ih @ x + b_ih + w_hh @ h + b_hh
    i, f, gg, o = g[:HID], g[HID:2*HID], g[2*HID:3*HID], g[3*HID:]
    c = sigmoid(f) * c + sigmoid(i) * np.tanh(gg)
    h = sigmoid(o) * np.tanh(c)
    d = np.maximum(wd @ h + bd, 0)
    return wa @ d + ba, h, c

def heads_argmax(logits):
    out, s = [], 0
    for n in SPLITS:
        out.append(int(np.argmax(logits[s:s + n])))
        s += n
    return out

# ---------- Compare ----------
rng = np.random.default_rng(0)
obs_seq = rng.normal(0, 0.5, size=(STEPS, OBS)).astype(np.float32)

rnn = torch.zeros(1, 2 * HID)
h = np.zeros(HID, np.float32)
c = np.zeros(HID, np.float32)

max_logit_err = max_state_err = 0.0
action_mismatch = 0
ref_logits_all = []
max_abs_z = 0.0

with torch.no_grad():
    for t in range(STEPS):
        if t == RESET_AT:
            rnn = torch.zeros(1, 2 * HID)
            h[:] = 0
            c[:] = 0

        obs_t = torch.from_numpy(obs_seq[t]).unsqueeze(0)
        nobs = model.normalize_obs({"obs": obs_t})
        max_abs_z = max(max_abs_z, float(nobs["obs"].abs().max()))
        out = model(nobs, rnn)
        ref_logits = out["action_logits"][0].numpy()
        rnn = out["new_rnn_states"]
        ref_logits_all.append(ref_logits.tolist())

        logits, h, c = manual_step(obs_seq[t], h, c)

        max_logit_err = max(max_logit_err, float(np.abs(logits - ref_logits).max()))
        ref_hc = rnn[0].numpy()
        max_state_err = max(max_state_err,
                            float(np.abs(h - ref_hc[:HID]).max()),
                            float(np.abs(c - ref_hc[HID:]).max()))
        if heads_argmax(logits) != heads_argmax(ref_logits):
            action_mismatch += 1

print(f"max logit error : {max_logit_err:.3e}")
print(f"max state error : {max_state_err:.3e}")
print(f"argmax mismatches: {action_mismatch}/{STEPS}")
print(f"max |normalized obs| in test: {max_abs_z:.2f} (clamp is at 5.0; if this is "
      f"near 5, folding won't match)")

if max_logit_err < TOL and max_state_err < TOL and action_mismatch == 0:
    print("ok")
else:
    print("error")

json.dump({"obs": obs_seq.tolist(), "logits": ref_logits_all, "reset_at": RESET_AT},
          open("test.json", "w"))
