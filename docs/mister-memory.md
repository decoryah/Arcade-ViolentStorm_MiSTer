# The MiSTer memory partition

The machine (`rtl/vs_core.sv`) sees five ROM ports and a tile RAM port, all level request / one-cycle ack. What sits behind
them is `target/mister/vs_mem.sv`, derived from the Metamorphic Force core's memory system (itself Monster Maulers', itself
the Gaiapolis core's; `docs/mister-memory.md` of gaiapolis-mister has the reasoning for the partition and the caches, which
carries over unchanged). What differs here is the data: the tile ROM is 4 MB (no K053250 ROM, and the tile codes the
renderer uses reach the first 2 MB), PCM is 4 MB of real data, and the tile rows come through a row cache.

| | MiSTer (DE10-Nano + SDRAM module) |
|---|---|
| SDRAM | 32 MB, 16 bit |
| DDR3 | the HPS's 1 GB, 64 bit, shared with Linux and the scaler: Flip Screen's frame buffers only |
| block RAM | 5.6 Mbit (553 M10K) |

## The partition

```
SDRAM   tiles         4 MB     2-word bursts   a tile row = 4 chunky bytes                                              K056832
        sprites       8 MB     4-word bursts   a 16-pixel row = 4 words (the four planes)                               K055673
        PCM           4 MB     single words    (2 x 2 MB of ROM)                                                        two K054539s
        68000 program 2 MB     behind a 16 KB cache, 8-word line fills (1 MB of ROM, the rest zeros)
        Z80 program   256 KB   behind a  4 KB cache, 8-word line fills (the 128 KB ROM twice)
DDR3    Flip Screen   2 frame buffers (flip_buf.sv), the finished picture
block   K056832 tile RAM  64K x 16, byte enables
RAM     tile row cache    512 x 40 (tags 512 x 17), sprite row cache 512 x 80
        plain RAM 60 KB, work RAM 64 KB, sprite RAM, palette (all in vs_main)
```

SDRAM word addresses (24 bits): tiles `0x000000`, PCM `0x200000`, sprites `0x400000`, program `0x800000`, sound program
`0x900000` (18.9 MB of the 32).

The image is stored as it comes: the regions with a row of more than one word keep the image's own order, so the loader
needs no address arithmetic beyond a region base, and a row's words are consecutive in the SDRAM and one burst. The tile
port returns `{w0, w1, 8'h00}` (40 bits: the fifth plane's byte is always 0 on this board) and the sprite port
`{w0..w3, 16'h0000}` (80 bits).

## The loader

The ROM image (`mra/*.mra`, `0x1240000` bytes, layout in the MRA header and `vs_mem.sv`) arrives from the HPS a byte at a
time. Pairs are merged into words, queued in a 64-entry FIFO (`dl_wait` holds the HPS off at 32), and a dispatcher
classifies each word by image offset, computes its address (a region base) and writes it as a byte-enabled SDRAM word.
The caches are swept on every download start. The default EEPROM is a separate download (MRA index 2), and the same index
is used to save and restore it (`<nvram>`).

### Fast load (the MRA's `address=` attribute)

With `address="0x32000000"` on the index-0 `<rom>`, a recent Main_MiSTer copies the whole assembled image into the DDR3 at that
byte address in one `memcpy`, bracketed by a download that has no data bytes: it starts with `ioctl_addr` = the image's length
(an ordinary download starts at 0, which is how `ViolentStorm.sv` tells them apart: `fast_dl`) and ends with it. The core
stays in reset from the start until `vs_mem` has pushed the whole image through the loader (`fl_done`). `vs_mem` reads the image
back in 256-byte blocks (a 32-beat burst through the arbiter's client port, `ddr_arb.sv` `c_*`, into a 32 x 64-bit buffer),
swaps each little-endian halfword to the image's big-endian word and pushes it into the loader's FIFO, as long as the FIFO has
room; the dispatcher behind it is unchanged, so the layout is the one above. The memory test (`mem_test.sv`) sums the bytes of the
image as they stream in, so the replay hands it the same bytes (high, then low, one word every three clocks) and its sums are
those of the image. Nothing else of the DDR3 is touched: the window's offset 0x400000 beats (byte 0x32000000, `FL_BASE`) is clear
of the Flip Screen buffers (0x80000 beats). The loader accepts about a word per ten clocks, so the 9.57 million words take about
a second; that, not the DDR3, is the limit. A Main_MiSTer that does not know the attribute streams the bytes as before, with
the same RBF and MRAs. `sim/emu/run_emu.sh` with `FAST=1` models the HPS side. This is the Metamorphic Force core's
implementation (`mf_mem.sv`, 20261013), taken over with this core's image layout.

## Video

The 8 MHz pixel clock comes from the 96 MHz system clock (a pixel every 12 clocks; a 512-pixel line is 6,144 clocks, the
budget the renderers were designed against). The mixer is two cores on alternate pixels (24 clocks each; see
`rtl/vs_mixer.sv`) and returns a pixel's colour one pixel period late; the core delays its de / sync signals to match.
Flip Screen (`flip_buf.sv`) turns the finished picture 180 degrees through two DDR3 frame buffers, as in the other cores,
with `W = 384`. CRT Adjust is rmonic79's module; with this raster the picture is 384 pixels in a line of 512, starting 106
pixels after the hsync pulse starts and ending 22 before the next, so H-Size goes to +2 (read period 48 + n quarter-clocks,
8 pixels a step) and H-Position to +20.

### The scandoubler needs the horizontal blank alone

`sys/scandoubler.v` (Scandoubler Fx, MiSTer.ini's `forced_scandoubler`) takes its line timing from the edges of `HBlank`:
`hb` falling starts a line (`hcnt`, `sd_hcnt`, `hde_start` and the sampling of `vb_in` hang on it), and it shifts `vs_in` /
`vb_in` through at those edges. It therefore expects `HBlank` to toggle on every line of the frame, the vertical blank lines
included, with `VBlank` separate. The first build gave it `~de`, where `de` is the visible *rectangle*: `HBlank` stayed high
through the whole vertical blank, the scandoubler's line counters ran on through the blank lines, and its doubled output had
no vertical sync at all (the monitor, or the HDMI scaler, saw a stream without frames: sound and a frozen picture). The
15 kHz path was unaffected: without the scandoubler `arcade_video` only uses the combined blank for `VGA_DE`.

`vs_video.sv` now also outputs `hde` (the horizontal window alone, level with `de`), delayed with the other signals in
`vs_core.sv`; `ViolentStorm.sv` gives `arcade_video` `HBlank = ~hde` and `VBlank = vblank` (registered with the rest in
`vq_*`). The CRT Adjust module and Flip Screen keep the combined blank (`hblank_c`), which is what they want; CRT Adjust is
gated off while the scandoubler is in use. Measured with the scandoubler on (`sim/emu/run_sd.sh`; `HONLY=0` is the old
wiring): the old wiring gives no vertical sync (`VGA_VS` 0 rises, `vs_sd` / `vb_sd` 0, with the mixer's input sync present);
the new one 528 lines a frame, 448 picture rows of 384 pixels (768 with HQ2x), a line period of 3,072 clocks and the frame
period exact (1,622,016 clocks), each source line twice in order, in forced, CRT 25 % and HQ2x modes.

Through the whole top level (`sim/emu/run_emu.sh` with the real image, 90 frames after the load): the 15 kHz run after
the change is identical to the run before it (output, 89 whole frame periods, geometry, byte-identical scaler picture);
with `FSD=1` (forced scandoubler) and `FX=2` (CRT 25 %) the output is 448 rows in 528 lines a frame, 384 pixels a row, 89
whole frame periods, and the even rows are byte-identical to the 15 kHz picture; with `FX=1` (HQ2x) 448 rows of 768
pixels, and the picture is the 15 kHz one smoothed (84,326 of 86,016 pixels identical, all 3,810 non-black source
pixels still non-black; the rest are HQ2x's edges).

### Scale (integer scaling for the HDMI scaler)

The OSD's Scale item (`status[34:32]`: Normal, V-Integer, HV-Integer, Narrower HV-Integer, HV-Integer+) goes to the framework's
`video_freak` (`sys/video_freak.sv`, with `sys/math.sv`), which sits behind `arcade_video` and turns the aspect ratio plus
the picture's own size into `VIDEO_ARX` / `VIDEO_ARY`. With Normal they pass through (4:3, or the ARC entries); with an integer
mode they carry the exact size in pixels (bit 12 set) that the scaler is to give the picture: the picture's row count times
the largest whole factor that fits the scaler's height, and a width that is the aspect ratio's (V-Integer) or a whole multiple
of the 384-pixel row (the HV modes: Narrower is the multiple below the aspect width, HV-Integer+ the one above, HV-Integer the
nearer of the two). The menu's order is the user's; `video_freak`'s `SCALE` input counts 0 Normal, 1 V-Integer, 2 Narrower,
3 HV-Integer+, 4 HV-Integer, and `ViolentStorm.sv` maps one onto the other (`scale_sel`).

Full Screen (Aspect ratio ARX = ARY = 0) has no proportions for the integer rule to size the width from, and the rule then
sizes the height from the width and asks for more rows than the screen has. With an integer Scale the core therefore hands
`video_freak` the scaler's own size (`HDMI_WIDTH` x `HDMI_HEIGHT`) as the proportions (`fs_int`), so Full Screen is the largest
whole-number picture in the screen's aspect; with the scaler's size unknown (direct video) it passes through as before.

## Tile ROM latency and the row cache

The tilemap fetches 196 tile rows a line (four layers of 49 groups) and each fetch waits for the SDRAM: without a cache the
line takes 6,113 clocks at a tile ROM latency of 26 clocks and 7,681 at 34 (budget 6,144). 86% of a frame's fetches hit
even a 64-entry direct-mapped cache (the empty tile and the repeated background tiles; measured over the 45 corpus
frames: 85.7% at 64 entries, 88.6% at 512), and with the 512-entry cache a hit costs 3 clocks: no late line at latencies
of 48 / 34 clocks (sprites / tiles) in 25 of 25 play frames, one frame of 25 with 8 late lines at 64 / 48.

## Verification

* `sim/tb_vs.cpp` (`tb_vs_top.sv`): `vs_core` behind `vs_mem` and a behavioural SDRAM chip, with the image streamed through the
  loader a byte at a time (or, with `BACKDOOR=1`, placed straight into the chip by the same address arithmetic). `ROMCHK=1`
  compares every tile and sprite read the renderers complete with the image while the game runs.
* `sim/emu/run_emu.sh`: the whole `emu` module of `ViolentStorm.sv` with the framework's own video path, the SDRAM chip and an
  Avalon DDR3 model; the loader check compares every word of the image with where the ports read it.
* `sim/emu/run_sd.sh`: this core's raster (`vs_video`) into the framework's `arcade_video` with Scandoubler Fx / the forced
  scandoubler selectable, nothing else (a fast check of the 31 kHz output; `HONLY=0` reproduces the first build's frozen
  picture). `FSD=1` / `FX=n` in `run_emu.sh` do the same through the whole top level.
  `FAST=1` models the HPS side of the MRA's `address=` attribute (the image copied into the DDR3 model, then a download with no
  bytes): the core must come out of reset on its own, the same loader check applies, and the scaler's picture must equal the
  streamed load's. `SCALE=0..4` / `AR=0..3` / `HW`, `HH` set the Scale item, the Aspect ratio and the scaler's output size,
  and the bench checks the size the core asks the scaler for against the framework's integer rule, worked out independently
  from the picture's rows and the settings. With the Diagnostic overlay on, the built-in memory test runs to its end (150
  frames after the load) after a fast load and after a streamed one: every region read back ok and stable, the tile RAM ok,
  and the two overlays differ only in the squares showing the 68000's instantaneous bus address (the fast load ends 250
  clocks after the streamed one in the bench).
* The built-in memory test (`mem_test.sv`, the diagnostic overlay's squares) reads every region back through the machine's own
  ports, twice: ok (read back what was loaded) and stable (the two passes agree), and tests the tile RAM with an address pattern.
