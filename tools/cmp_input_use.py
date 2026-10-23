"""Compare the checksum runs of tools/input_use.ps1:  python tools/cmp_input_use.py <dir with iu_*.csv>

A run's rows are "frame,sprite_sum,wram_sum" every 25 frames. An input the game does not use leaves both sums equal to the
baseline's at every frame; one it uses makes them differ from the frame it first matters."""
import sys

d = sys.argv[1]


def load(name):
    rows = {}
    with open(f"{d}/iu_{name}.csv") as f:
        for line in f.read().split("\n")[1:]:
            if line:
                fr, s, w = line.split(",")
                rows[int(fr)] = (s, w)
    return rows


def compare(base, other, start=0):
    fr = [f for f in sorted(set(base) & set(other)) if f >= start]
    ds = [f for f in fr if base[f][0] != other[f][0]]
    dw = [f for f in fr if base[f][1] != other[f][1]]
    return len(fr), ds, dw


def line(label, base, name, start=0):
    n, ds, dw = compare(base, load(name), start)
    print(f"  {label:34s} sprite RAM differs at {len(ds):3d} of {n} samples (first {ds[0] if ds else '-':>4}), "
          f"work RAM at {len(dw):3d} (first {dw[0] if dw else '-':>4})")


print("scripted play, 4000 frames, against the first baseline run:")
b = load("drop_base1")
line("baseline again (determinism)", b, "drop_base2")
line("P1 button 1 never pressed", b, "drop_b1")
line("P1 button 2 never pressed", b, "drop_b2")
line("P1 button 3 never pressed", b, "drop_b3")

print("each character, P1 button 3 held from frame 600 against not held:")
for sel, who in ((0, "Wade"), (1, "Boris"), (2, "Kyle")):
    line(f"{who}", load(f"char_sel{sel}_free"), f"char_sel{sel}_held")
w0 = load("char_sel0_free")
for sel, who in ((1, "Boris"), (2, "Kyle")):
    n, ds, _ = compare(w0, load(f"char_sel{sel}_free"))
    print(f"  ({who}'s unheld run differs from Wade's in sprite RAM at {len(ds)} of {n} samples: the cursor moves took)")

print("service menu, an input held from frame 1500 against nothing held (frames from 1500 on):")
s0 = load("svc_none")
for name, label in (("p1b1", "P1 button 1 (attack: exits)"), ("p1b3", "P1 button 3"), ("p2b3", "P2 button 3"),
                    ("p3b3", "P3 button 3")):
    line(label, s0, f"svc_{name}", 1500)
