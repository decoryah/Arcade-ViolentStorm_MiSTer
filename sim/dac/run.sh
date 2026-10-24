#!/bin/sh
# rtl/vs_dac.sv against its table (iverilog): sim/dac/run.sh
set -e
cd "$(dirname "$0")"
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
mkdir -p "$HOME/build_dac"
iverilog -g2012 -o "$HOME/build_dac/tb_vs_dac" tb_vs_dac.sv ../../rtl/vs_dac.sv
vvp "$HOME/build_dac/tb_vs_dac"
