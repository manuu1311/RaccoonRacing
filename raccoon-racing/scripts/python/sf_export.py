import torch, json

path = "/mnt/dump/dump-projects/Godot/RaccoonRacing/raccoon-racing/scripts/python/logs/sf/curriculum/checkpoint_p0/checkpoint_000002936_3006464.pth"
ckpt = torch.load(path, map_location="cpu", weights_only=False)

print(ckpt.keys())          # expect: model, optimizer, train_step, env_steps, ...
sd = ckpt["model"]
for k, v in sd.items():
    print(k, tuple(v.shape), v.dtype)

n = "obs_normalizer.running_mean_std.running_mean_std.obs."
e = "encoder.encoders.obs.mlp_head."
order = [
    e + "0.weight", e + "0.bias", e + "2.weight", e + "2.bias",
    "core.core.weight_ih_l0", "core.core.weight_hh_l0",
    "core.core.bias_ih_l0", "core.core.bias_hh_l0",
    "decoder.mlp.0.weight", "decoder.mlp.0.bias",
    "action_parameterization.distribution_linear.weight",
    "action_parameterization.distribution_linear.bias",
]
with open("agent.bin", "wb") as f:
    for k in order:
        f.write(sd[k].detach().cpu().numpy().astype("<f4").tobytes())
print("ok")
