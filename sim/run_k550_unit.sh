#!/bin/sh
# K055550 unit bench: random programs of every command against a transcription of MAME's K055550_word_w
#   sim/run_k550_unit.sh [seed [commands]]
set -e
cd "$(dirname "$0")"
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
OBJ="${OBJ:-$HOME/build_vs/k550}"
mkdir -p "$OBJ"
verilator --cc --exe --build -j 4 -O2 -Wno-fatal -Wno-WIDTH -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY \
    -Wno-IMPLICIT -Wno-TIMESCALEMOD -Wno-CASEINCOMPLETE -Wno-MULTIDRIVEN -Wno-LATCH -Wno-UNSIGNED \
    --top-module tb_k550_top --prefix Vtb_k550_top -Mdir "$OBJ" \
    ../rtl/k055550.sv tb_k550_top.sv tb_k550.cpp > "$OBJ/build.log" 2>&1 || { grep -E "%Error|error:" "$OBJ/build.log" | head -20; exit 1; }
"$OBJ/Vtb_k550_top" "${1:-1}" "${2:-60}"
