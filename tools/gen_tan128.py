#!/usr/bin/env python3
"""rtl/data/tan128.hex: T[k] = round(tan(k * pi / 128) * 2^40), k = 0..63, one 46-bit value a line (12 hex digits).
The K055550's homing-vector command (rtl/k055550.sv) searches these. Computed with 80-digit decimals."""
import sys, os
from decimal import Decimal, getcontext
getcontext().prec = 90
PI = Decimal("3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798")

def sincos(x):
    # Taylor series, |x| < pi/2
    term_s, term_c = x, Decimal(1)
    s, c = x, Decimal(1)
    n = 1
    for _ in range(80):
        term_c = -term_c * x * x / (Decimal((2 * n - 1)) * Decimal(2 * n))
        term_s = -term_s * x * x / (Decimal(2 * n) * Decimal(2 * n + 1))
        c += term_c; s += term_s; n += 1
    return s, c

out = []
for k in range(64):
    if k == 0:
        out.append(0); continue
    s, c = sincos(PI * k / 128)
    t = s / c * (Decimal(2) ** 40)
    out.append(int(t.to_integral_value()))
assert out[32] == 1 << 40
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "rtl", "data", "tan128.hex")
with open(path, "w", newline="\n") as f:
    for v in out:
        assert v < (1 << 46)
        f.write("%012x\n" % v)
print("wrote", os.path.normpath(path), "T[63] = %.6f" % (out[63] / 2 ** 40))
