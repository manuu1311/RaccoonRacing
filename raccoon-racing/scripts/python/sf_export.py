import json
from pathlib import Path

import numpy as np
import torch
import gymnasium as gym

from sample_factory.model.actor_critic import create_actor_critic
from sample_factory.utils.attr_dict import AttrDict

CKPT = "/mnt/dump/dump-projects/Godot/RaccoonRacing/raccoon-racing/scripts/python/train/competitive/RaccoonRacing/checkpoint_p0/checkpoint_000086364_100032512.pth"
BIN = "agent.bin"
TOL = 1e-4
STEPS = 40
RESET_AT = 20          # simulate an episode reset mid-sequence
SPLITS = [3, 3, 2]     # throttle, steer, special

OBS, H, HID, DEC, OUT = 384, 256, 128, 128, 8

# ---------- Sample Factory reference ----------
exp_dir = Path(CKPT).parent.parent
cfg = AttrDict(json.load(open(exp_dir / "config.json")))

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

rnn = torch.zeros(1, 2 * HID)           # SF layout: [h, c]
h = np.zeros(HID, np.float32)
c = np.zeros(HID, np.float32)

max_logit_err = max_state_err = 0.0
action_mismatch = 0
ref_logits_all = []

with torch.no_grad():
    for t in range(STEPS):
        if t == RESET_AT:
            rnn = torch.zeros(1, 2 * HID)
            h[:] = 0
            c[:] = 0

        obs_t = torch.from_numpy(obs_seq[t]).unsqueeze(0)
        nobs = model.normalize_obs({"obs": obs_t})
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

if max_logit_err < TOL and max_state_err < TOL and action_mismatch == 0:
    print("ok")
else:
    print("error")

# Optional: dump the same sequence for testing the GDScript port
json.dump({"obs": obs_seq.tolist(), "logits": ref_logits_all, "reset_at": RESET_AT},
          open("test.json", "w"))
