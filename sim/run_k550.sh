#!/bin/sh
# the homing-vector check: all 2^32 inputs (a minute on 8 cores) or sampled with a step: sim/run_k550.sh [step]
set -e
cd "$(dirname "$0")/.."
g++ -O2 -fopenmp -o /tmp/k550_ref sim/k550_ref.cpp
/tmp/k550_ref rtl/data/tan128.hex "${1:-1}"
