#!/bin/sh
# Verilator lint of the machine and the memory subsystem: sim/lint.sh
cd "$(dirname "$0")"
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
verilator --lint-only -Wno-fatal -Wno-WIDTH -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNOPTFLAT -Wno-PINCONNECTEMPTY \
    -Wno-IMPLICIT -Wno-TIMESCALEMOD -Wno-CASEINCOMPLETE -Wno-MULTIDRIVEN -Wno-LATCH -Wno-UNSIGNED -Wno-CMPCONST \
    -Wno-PROCASSWIRE -Wno-SYNCASYNCNET -Wno-BLKSEQ +1364-2005ext+v waivers.vlt --top-module vs_core \
    ../rtl/*.sv ../modules/cpu-tg68k/gen/tg68k.v ../modules/cpu-tv80/*.v 2>&1 | grep -E "%Error|%Warning-(WIDTH|CASEINCOMPLETE|LATCH)" | head -${1:-40}
echo "--- mem"
verilator --lint-only -Wno-fatal -Wno-WIDTH -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY -Wno-TIMESCALEMOD \
    --top-module vs_mem ../target/mister/vs_mem.sv ../target/mister/rom_cache.sv ../target/mister/mem_test.sv \
    ../target/mister/sdram_ctrl.sv 2>&1 | grep -E "%Error" | head -20
