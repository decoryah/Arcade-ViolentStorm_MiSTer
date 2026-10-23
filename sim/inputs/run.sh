#!/bin/sh
# vs_inputs against the previous decode and a table of the cabinet's names (iverilog): sim/inputs/run.sh
set -e
cd "$(dirname "$0")"
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
mkdir -p "$HOME/build_vsinputs"
iverilog -g2012 -o "$HOME/build_vsinputs/tb_vs_inputs" tb_vs_inputs.sv ../../rtl/vs_inputs.sv
vvp "$HOME/build_vsinputs/tb_vs_inputs"
