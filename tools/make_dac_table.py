#!/usr/bin/env python3
"""make_dac_table.py [out.hex] : the OSD's Colours = Board DAC table (rtl/data/k054573_dac.hex): 64 brightness steps x 256
colour codes, one byte each (address = brightness[7:2] * 256 + code).

The board turns each 8-bit colour into a voltage with a Konami 054573 per channel, and the K054338's brightness output
sets the current those DACs run on through a 054574. Traced from the Gerbers and BOM of Ace's 054573 reproduction
(https://www.ukvac.com/forum/threads/konami-054573-and-054574-reproductions.84054/) by the Gaiapolis core (its
tools/make_dac_table.py; this model is that one): eight open-collector 74LS07 outputs, one per bit, pull a summing node
down through 49k, 24k, 12k, 6k, 3.1k, 1.7k, 800R and 380R (D0..D7) when the bit is 0; the node has 1.2k to ground and is
fed by a current source (the brightness); two diodes and an NPN emitter follower with 220R take it to the output. A
conductance divider, not a resistor ladder: the output rises faster near the top, so mid tones are darker than a linear
DAC (MAME) gives.

Fitted to a recording of a Violent Storm PCB (VER. EAB; BB4's "VIOLENT STORM Arcade Real Hardware Framemeister + OSSC",
https://www.youtube.com/watch?v=0hEZvGd4whM; docs/hardware.md "Colours"):
  * the curve: 14.5 mA, the Gaiapolis value (rms 3.7 of 255 on five still screens against 12.9 for a linear DAC; the best
    current for this recording, about 32 mA, gives 3.4 -- the minimum is flat from 14 to 35 mA)
  * the brightness: it scales the DACs' current, after the colour is mixed (MAME scales the colour itself); on the
    player-select fade the effective current is b_eff / 255 of the full one with
        b_eff = 255 + 1.2787 (reg - 255) + 0.002090 (reg - 255)^2      (rms 2.7 over the fade)
    so it never falls below about a quarter, where the DAC's output is already black.
Row i is brightness 4i + 3 (row 63 is 255, the full brightness of every still screen). Each row maps code 0 at full
brightness to 0 and code 255 at full brightness to 255: row 63 is the plain curve, the others are darker."""
import math
import sys

VT = 0.02585
R_BITS = [49000, 24000, 12000, 6000, 3100, 1700, 800, 380]
ISRC, VOL, BETA = 14.5e-3, 0.2, 200
C1, C2 = 1.2787, 0.002090


def diode_v(i, Is=1e-9, n=1.8): return n * VT * math.log(i / Is + 1) if i > 0 else 0.0
def vbe(i, Is=1e-14): return VT * math.log(i / Is + 1) if i > 0 else 0.0


def follower(v29):
    """the emitter follower into 220R: the output voltage for base voltage v29, and its emitter current"""
    lo, hi = 0.0, max(v29, 0.0)
    for _ in range(60):
        vo = (lo + hi) / 2
        if vo + vbe(vo / 220) > v29: hi = vo
        else: lo = vo
    vo = (lo + hi) / 2
    return vo, vo / 220


def node(code, v29):
    """the current the summing node takes for follower base voltage v29, and the output voltage"""
    vo, ie = follower(v29)
    id2 = v29 / 2000 + ie / (BETA + 1); v31 = v29 + diode_v(id2)
    id1 = v31 / 1100 + id2;             v11 = v31 + diode_v(id1)
    i = v11 / 1200 + id1
    for b in range(8):
        if not (code >> b) & 1: i += max(0.0, v11 - VOL) / R_BITS[b]
    return i, vo


def vout(code, isrc):
    lo, hi = 0.0, 11.0
    for _ in range(60):
        m = (lo + hi) / 2
        if node(code, m)[0] > isrc: hi = m
        else: lo = m
    return node(code, (lo + hi) / 2)[1]


def b_eff(reg):
    return 255 + C1 * (reg - 255) + C2 * (reg - 255) ** 2


v0, v255 = vout(0, ISRC), vout(255, ISRC)
tab = []
for row in range(64):
    isrc = ISRC * b_eff(4 * row + 3) / 255
    for c in range(256):
        tab.append(max(0, min(255, round(255 * (vout(c, isrc) - v0) / (v255 - v0)))))
out = sys.argv[1] if len(sys.argv) > 1 else 'rtl/data/k054573_dac.hex'
open(out, 'w', newline='\n').write(''.join('%02x\n' % t for t in tab))
full = tab[63 * 256:]
print(out, '(64 x 256)  full brightness:', ' '.join('%d:%d' % (c, full[c]) for c in (0, 32, 64, 96, 128, 160, 192, 224, 255)))
print('code 255 by brightness 255 / 191 / 127 / 63 / 3:', ' '.join(str(tab[r * 256 + 255]) for r in (63, 47, 31, 15, 0)))
