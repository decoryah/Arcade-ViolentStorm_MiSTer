#!/bin/sh
# Furrtek's K053252 model run with a register set:   sim/k053252/run.sh <name> <32 hex digits = regs 0..15>
# prints the edges of NHBK / NHSY / NVBK / NVSY with the time in pixel clocks (CLK2, the 32 MHz input / 4).
set -e
cd "$(dirname "$0")"
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
N="$1"; R="$2"
iverilog -g2012 -DREGS="128'h$R" -o "/tmp/k252_$N" tb_k252.v 053252.v
vvp "/tmp/k252_$N" | grep '^t='
