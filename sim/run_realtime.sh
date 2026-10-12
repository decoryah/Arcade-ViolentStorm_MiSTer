#!/bin/sh
# The frame bench with the line budget enforced (REALTIME=1) and the memories' latencies modelled:
#   sim/run_realtime.sh <states dir> <image.rom> [LAT_SROM [LAT_TROM [LAT_VRAM]]]
# Prints, per state, how many lines were still being rendered when the next pulse came and the picture's
# difference from MAME's. Needs run_frames.sh to have built the bench ($OBJ).
cd "$(dirname "$0")"
D="$1"; IMG="$2"; SROM="${3:-48}"; TROM="${4:-34}"; VRAM="${5:-0}"
OBJ="${OBJ:-$HOME/build_vs/frame}"
for s in $(ls "$D"/state_*.txt | sort -t_ -k2 -n); do
  f=$(basename "$s" .txt); f=${f#state_}
  [ -f "$D/snap_$f.png" ] || continue
  REALTIME=1 "$OBJ/Vtb_frame_top" "$s" "$IMG" ../rtl/data/zoom.hex ../rtl/data/recip.hex "$D/rtl/rt_$f.rgb" +LAT_SROM=$SROM +LAT_TROM=$TROM +LAT_VRAM=$VRAM > "$D/rtl/rt_$f.log" 2>&1
  late=$(grep "REALTIME:" "$D/rtl/rt_$f.log" | sed 's/REALTIME: //')
  res=$(python3 ../tools/cmp_frame.py "$D/rtl/rt_$f.rgb" "$D/snap_$f.png" 2>&1 | head -1)
  echo "frame $f: $late | $res"
done
