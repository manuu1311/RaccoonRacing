import argparse, os
import numpy as np
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

'''
USAGE
python tb_summary.py ../train/competitive --last 20 --chunks 8 --filter kl clip learning_rate entropy loss ratio reward fps
'''
p = argparse.ArgumentParser()
p.add_argument("logdir")
p.add_argument("--chunks", type=int, default=8)
p.add_argument("--last", type=float, default=0, help="only last N million steps (0 = all)")
p.add_argument("--filter", nargs="*", default=[])
a = p.parse_args()

files = []
for root, _, names in os.walk(a.logdir):
    files += [os.path.join(root, n) for n in names if n.startswith("events.out.tfevents")]
if not files:
    raise SystemExit(f"no event files found under {a.logdir}")

series = {}
for d in sorted({os.path.dirname(f) for f in files}):
    ea = EventAccumulator(d, size_guidance={"scalars": 0})
    ea.Reload()
    for tag in ea.Tags()["scalars"]:
        series.setdefault(tag, []).extend((e.step, e.value) for e in ea.Scalars(tag))

# reference range: the largest step seen in any tag
hi = max(s for pts in series.values() for s, _ in pts)
lo = max(0, hi - a.last * 1e6) if a.last > 0 else min(s for pts in series.values() for s, _ in pts)
edges = np.linspace(lo, hi + 1, a.chunks + 1)

print(f"steps {lo/1e6:.2f}M -> {hi/1e6:.2f}M, {a.chunks} slices, ends (M): "
      + " ".join(f"{e/1e6:.1f}" for e in edges[1:]))
print(f"{'tag':44s}" + "".join(f"{'s'+str(i+1):>9s}" for i in range(a.chunks)) + "   min / max")

for tag in sorted(series):
    if a.filter and not any(f in tag for f in a.filter):
        continue
    pts = sorted(series[tag])
    steps = np.array([s for s, _ in pts], dtype=float)
    vals = np.array([v for _, v in pts], dtype=float)
    keep = np.isfinite(vals) & (steps >= lo)
    steps, vals = steps[keep], vals[keep]
    if len(vals) == 0:
        continue
    idx = np.digitize(steps, edges) - 1
    row = "".join(
        f"{vals[idx == i].mean():9.3g}" if (idx == i).any() else f"{'-':>9s}"
        for i in range(a.chunks)
    )
    print(f"{tag[:43]:44s}{row}   {vals.min():.3g} / {vals.max():.3g}")
