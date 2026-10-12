import sys, re
# summarize a run.sh output: hblank / hsync / vblank / vsync widths and spacing, in pixel clocks and lines
ev = {}
for line in sys.stdin:
    m = re.match(r't=(\d+) (\w+) (\d)', line)
    if m: ev.setdefault(m.group(2), []).append((int(m.group(1)), int(m.group(3))))
def edges(sig):
    return ev.get(sig, [])
def periods(sig):
    e = edges(sig)
    falls = [t for t, v in e if v == 0]; rises = [t for t, v in e if v == 1]
    return falls, rises
for s in ('NHBK', 'NHSY', 'NVBK', 'NVSY'):
    f, r = periods(s)
    print(s, 'falls', f[:5], 'rises', r[:5])
f_hb, r_hb = periods('NHBK'); f_hs, r_hs = periods('NHSY')
f_vb, r_vb = periods('NVBK'); f_vs, r_vs = periods('NVSY')
# find a full cycle after the registers settle (skip the first edge or two)
def cyc(f, r, skip=2):
    f = f[skip:]; r = [x for x in r if x > f[0]]
    return f, r
f, r = cyc(f_hb, r_hb)
print('HBLANK: low width (px) =', r[0] - f[0], ' period =', f[1] - f[0])
hs_f, hs_r = cyc(f_hs, r_hs)
print('HSYNC : low width (px) =', hs_r[0] - hs_f[0], ' period =', hs_f[1] - hs_f[0])
# hsync start relative to hblank start (first hsync fall at or after a hblank fall)
print('hsync starts', hs_f[0] - f[0] if hs_f[0] >= f[0] else hs_f[1] - f[0], 'px after hblank starts')
line = f[1] - f[0]
vf, vr = cyc(f_vb, r_vb, 1)
print('VBLANK: low width (lines) = %.2f  period (lines) = %.2f' % ((vr[0] - vf[0]) / line, (vf[1] - vf[0]) / line))
sf, sr = cyc(f_vs, r_vs, 1)
print('VSYNC : low width (lines) = %.2f' % ((sr[0] - sf[0]) / line))
d = (sf[0] - vf[0]) / line
print('vsync starts %.2f lines after vblank starts' % (d if d >= 0 else (sf[1] - vf[0]) / line))
