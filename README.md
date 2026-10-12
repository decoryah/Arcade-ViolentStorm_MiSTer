# Violent Storm for MiSTer

A MiSTer FPGA core for **Violent Storm** (Konami, 1993), the four-player beat-'em-up on the "pre-GX" GX168 board. It is
built on the Metamorphic Force and Monster Maulers cores (which come from plasticbugs' Gaiapolis core for the Analogue
Pocket): the same 68000 / Z80 / K056832 / K055673 / K055555 / K054338 / K054539 board family, with this game's map, a
384 x 224 picture at an 8 MHz pixel clock and the K055550 helper chip.

**Status.** The first build, `violentstorm_20261012`, was tested on a real MiSTer by the repository owner: the game works in
all areas. It has one known fault, a frozen picture with Scandoubler Fx or `forced_scandoubler` (see below), fixed in
`releases/violentstorm_20261013.rbf` (Quartus 17.0.2: 46 % ALMs, 520 / 553 M10K, 74 / 112 DSPs, every clock's slack positive:
+0.74 ns on the 96 MHz core clock, +0.23 ns the tightest hold). That build has been checked in simulation only (against
MAME 0.289, the benches under `sim/`) and is not yet tested on a board. Everything in the verification table below was
checked in simulation.

## What is verified (against MAME 0.289, `viostorm`)

| | |
|---|---|
| ROM path | the image built from `mra/*.mra` equals MAME's loaded regions (32 slices of 4 sets, 0 mismatches) |
| Video | 86 of 86 frozen-state corpus frames (attract mode, scripted play up to frame 10,000 and the attract mode's demo play of the later stages up to frame 26,800) **pixel-identical** to MAME's snapshots, also with the line budget enforced and SDRAM latencies of 48 / 34 clocks (no late line) |
| K055550 | every command (memset, copy, collision list, homing vector) against a transcription of MAME's code on random programs: 1,660 commands, 0 differences; the homing vector for all 2^32 inputs |
| Sound | the K054539 pair replayed from MAME's register log correlates 0.92-0.98 a second with MAME's own stream (the log's +-1 sample timing is the rest) |
| Whole machine | from reset (with the power-on check skipped) to the character select: the same picture as MAME's at frames 60 and 300, and at 500 (a few frames' timeline offset); the MiSTer top level end to end (`sim/emu`: loader check of all 9.5 M words, frame period exactly 1,622,016 clocks = 59.1856 Hz, 384 x 224, EEPROM save path) passes, also with CRT Adjust on (amounts 0, and H-Size +2 / H-Position -6 / V-Shift -3: the picture exactly 400 pixels wide and 3 lines up), and the Flip Screen bench with the 384-pixel raster |

## Install

1. Copy the RBF to `/media/fat/_Arcade/cores/` and the `.mra` files from `mra/` to `/media/fat/_Arcade/`. Keep the
   RBF's `violentstorm_` name and date: MiSTer finds the core by the MRA's `<rbf>` name plus the date.
2. Put your MAME 0.289 `viostorm.zip` in `/media/fat/games/mame/` (the merged set holds all versions, or the clone zips
   `viostormu.zip`, `viostormj.zip` ... next to it). No ROMs are distributed.
3. Start `Violent Storm (World ver EAC)` (or the USA / Japan / Asia version) from the Arcade menu. The ROM image is 18 MB.
   The game's power-on RAM / ROM check takes about 14 seconds, as on the board.

| Set | MRA |
|---|---|
| `viostorm` | Violent Storm (World ver EAC) |
| `viostormeb` | Violent Storm (World ver EAB) |
| `viostormu` | Violent Storm (USA ver UAC) |
| `viostormub` | Violent Storm (USA ver UAB) |
| `viostormj` | Violent Storm (Japan ver JAC) |
| `viostorma` | Violent Storm (Asia ver AAC) |
| `viostormab` | Violent Storm (Asia ver AAB) |

The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.

## OSD options

| Option | Values | |
|---|---|---|
| Aspect ratio | Original, Full Screen, [ARC1], [ARC2] | Original is 4:3 |
| Flip Screen | Off, On | The picture turned 180 degrees on every output (a frame buffer in the DDR3: one frame of delay while on) |
| Scandoubler Fx | None, HQ2x, CRT 25%, CRT 50%, CRT 75% | |
| CRT Adjust | submenu: Off, On; H-Size 0..+2 / -16..-1, H-Position -48..+20, V-Shift -16..+15 | Fits the picture to a 15 kHz analog output. Does nothing while the scandoubler is in use |
| Number of Players | 2, 3 | The board's DIP |
| Coin Mechanism | Common, Independent | The board's DIP |
| Audio | Stereo, Mono | The board's DIP; Mono puts the left mix on both channels |
| Test Mode | Off, On | The board's test switch: the game's service menu |
| Diagnostic overlay | Off, On | Three rows of 32 squares along the bottom of the picture, and the built-in memory test after each ROM load |
| SDRAM read capture | Normal, Late | For a module that answers slowly |
| Reset | | Restarts the machine |

On a gamepad the default mapping is A / B / R for buttons 1 / 2 / 3, Start for Start and Select for Coin; up to four
joysticks. From the keyboard: 1-4 start, 5-8 coin and F2 for the test switch.

Scandoubler Fx and MiSTer.ini's `forced_scandoubler` make the core's 15 kHz picture a 31 kHz one (every line twice; HQ2x
and the CRT filters on top). In the first build (`violentstorm_20261012`) they gave no vertical sync at all, so the monitor
or the HDMI scaler showed a frozen picture: the framework's scandoubler takes its line timing from the horizontal blank's
edges and needs them on every line, vertical blanking included, and this core's blank was the picture window, high through
the whole vertical blank. Fixed in `violentstorm_20261013`: the core now gives it the horizontal blank alone (`hde` from
`vs_video.sv`) with the vertical blank separate (the same fix as Gaiapolis's `gaiapolis_20261011`). With the 15 kHz output
the picture and its timing are as they were (byte-identical in the top-level bench).

## What differs from Metamorphic Force

| | Metamorphic Force | Violent Storm |
|---|---|---|
| picture | 288 x 224, 6 MHz | 384 x 224, **8 MHz**, 512 x 264, 59.1856 Hz |
| SUB1 plane | K053250 | none |
| protection | none | **K055550**: memset, collision list, homing vector |
| tile mix | not used | **category-1 tiles blended at the last tile code's level** (the game's fades) |
| plain RAM | 12 KB used | 60 KB |
| mixer | one core, 16 clocks a pixel | **two cores on alternate pixels**, one pixel of latency |
| tile ROM | 2 MB, no cache | 4 MB, **512-entry row cache** (four layers of 49 tiles a line) |

## Known differences from MAME

* The K055550 takes time here (it holds the 68000 while a command runs, about 2,500 clocks a frame in play); MAME's
  commands are instant. The game reads results only after the command, so the program sees MAME's values.
* The renderer reaches the first 2 MB of the 4 MB tile ROM (16-bit tile codes, as MAME's callback does not extend them);
  the whole ROM is reachable through the 310000 read-back window the power-on check uses.
* `m_last_alpha_tile_mix_code` (the category-1 tiles' level) follows the tiles in raster order here, MAME's tilemap
  decode order there; identical in every corpus frame.
* No hardware test yet; no later-stage or boss corpus yet (see `PLAN.md`).

## Repository layout

| Path | |
|---|---|
| `ViolentStorm.sv`, `ViolentStorm.q*`, `ViolentStorm.sdc`, `files.qip` | the MiSTer top level (`emu`), Quartus project, timing constraints |
| `rtl/` | the machine: `vs_core` (the board), `vs_main` (68000 map), `k055550`, `vs_video`, `vs_mixer`, `vs_sound`, renderers (`k056832_tilemap`, `k053247_*`), `k054539`, `k054321`, `er5911` (`rtl/data/` generated tables, `rtl/pll*` the clock PLL) |
| `target/mister/` | the memory subsystem (`vs_mem`, `rom_cache`, `ddr_arb`), SDRAM controller, memory test, Flip Screen |
| `modules/` | vendored TG68K.C, tv80 and CRT Adjust |
| `sys/` | the MiSTer framework (identical to Template_MiSTer) |
| `mra/` | the seven MRAs, generated by `tools/make_mra.py` |
| `sim/` | Verilator benches: frozen-state frames, real-time budget, whole machine, K054539 replay, K055550 homing vector, K053252 model, Flip Screen, the MiSTer top level end to end |
| `tools/` | MRA generator and ROM image builder (`vs_rom.py`), comparison tools, MAME Lua probes, the generators of `rtl/data` (`gen_*.py`) |
| `docs/` | `hardware.md`, `mister-memory.md` |

## Building

Quartus Prime Lite 17.0.2 (the version MiSTer's framework is built with):

```
quartus_sh --flow compile ViolentStorm
```

`tools/make_mra.py viostorm.zip` regenerates the MRAs. The simulation benches need Verilator 5 and a C++ compiler, and a
ROM image you build yourself from your own romset (it checks every part's CRC and the image's md5):

```
python tools/mra_build.py "mra/Violent Storm (World ver EAC).mra" viostorm.zip viostorm.rom   # 19,136,512 bytes
python tools/vs_rom.py viostorm.zip viostorm.rom                                              # against MAME's regions
```

MAME (0.289) is run by `tools/mame_run.ps1` with the Lua probes of `tools/lua/`; `tools/make_corpus.ps1` makes a corpus of
frozen states, `sim/run_frames.sh` renders it and compares with MAME's snapshots.

## Credits

* **plasticbugs** -- the Gaiapolis core for the Analogue Pocket, the machine this one is built on (`rtl/`, the SDRAM
  controller `target/mister/sdram_ctrl.sv` and the memory test `mem_test.sv`, adapted; `tools/mra_build.py`), and through
  it the MAME team's work as the reference, **Tobias Gubener**'s TG68K.C (LGPL-3.0) and **Guy Hutchison**'s tv80 (MIT),
  vendored under `modules/`.
* **Claude** (Anthropic's AI model, used through Claude Code) -- the Violent Storm machine changes and the MiSTer
  layer, written together with the repository owner: the K055550, the 384-pixel raster and the two-core mixer, the
  tile mix codes and row cache, the ROM path, the simulation benches and this documentation.
* **Sorgelig** and the MiSTer team -- the framework (`sys/`, GPL).
* **rmonic79** (Umberto Parisi), with help from **Andrea Bogazzi** (asturur) --
  [MiSTer-CRT-Adjust](https://github.com/rmonic79/MiSTer-CRT-Adjust), the module behind the CRT Adjust options
  (`modules/crt-adjust/crt_adjust.sv`; GPL-3.0 or later).
* **furrtek** -- [SiliconRE](https://github.com/furrtek/SiliconRE/tree/master/Konami)'s silicon-traced models and notes of
  the K053252 timing chip (the raster, run here as `sim/k053252`), the K054338 and K055555.
* **Jose Tejada (jotego)** -- JTFRAME's MiSTer SDRAM clock phase and read-capture timing, which this core's PLL and
  controller settings follow; and, with the other authors of the independent Konami cores read as references (jlrh's
  `konami-fpga`, ppriest's `Arcade-KonamiGX_MiSTer`), the cross-checks of the K054338, K055555, K056832 and K055673.

## Licence

Copyright (C) 2026 decoryah. GPL-3.0, as the Pocket core this is built on (see `LICENSE`). The vendored TG68K.C (LGPL-3.0), CRT Adjust (GPL-3.0 or
later) and tv80 (MIT) in `modules/` keep their own licences, and the MiSTer framework in `sys/` is GPL (see the headers of its files).
