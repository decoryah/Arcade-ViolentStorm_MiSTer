# Violent Storm -- Konami "pre-GX" hardware (GX168)

Source of truth: MAME 0.289 `src/mame/konami/mystwarr.cpp` (machine `viostorm`, sets `viostorm`, `viostormeb`,
`viostormu`, `viostormub`, `viostormj`, `viostorma`, `viostormab`), `mystwarr_v.cpp`, `konamigx_v.cpp`,
`konamigx_m.cpp` (the K055550) and the other device files named below; SiliconRE (furrtek) for the K053252's timing
and the K054338 / K055555 notes. Everything else was measured with the Lua probes in `tools/lua/`. The machine is the
Metamorphic Force core's (itself Monster Maulers' and Gaiapolis') with this game's map, no K053250, the K055550 helper
chip, and a 384 x 224 picture at an 8 MHz pixel clock.

## 1. Board

| | |
|---|---|
| Game | Violent Storm (EAC / EAB / UAC / UAB / JAC / AAC / AAB), Konami 1993 |
| Board | GX168, the "pre-GX" family it shares with Mystic Warriors, Monster Maulers, Metamorphic Force, Martial Champion, Gaiapolis |
| Main CPU | MC68000 @ 16.000 MHz (32 MHz / 2) |
| Sound CPU | Z80 @ 8.000 MHz (32 MHz / 4) |
| Sound | 2 x K054539 @ 18.432 MHz, stereo (+ K054321 latch / master volume) |
| EEPROM | ER5911, 128 x 8 |
| Display | 384 x 224 visible, ROT0, 8 MHz pixel clock, 512 x 264 -> 15.625 kHz, 59.1856 Hz |
| Palette | 2048 entries, xRGB_888, shadows + highlights |
| ROM | 1 MB program (2 x 512 KB), 128 KB sound program (twice), 4 MB tiles (4bpp, 2 x 2 MB), 8 MB sprites (4bpp), 4 MB PCM (2 x 2 MB) |

### Raster

The K053252 is programmed once at boot (registers 0..13 = `01 FF 00 16 00 39 00 00 01 07 11 0E 75 00`, written by the
reset code at 0x4a6..0x4de). Furrtek's silicon-derived model of the chip (`ref/siliconre/053252_hdl_053252.v`, run with
those values by `sim/k053252/run.sh`; the same run reproduces the numbers the Metamorphic Force and Monster Maulers cores
were built on) gives, at 32 MHz / 4 = 8 MHz:

* 512 pixels x 264 lines, 15.625 kHz, 59.1856 Hz;
* hblank 127 pixels (the chip's active period is 385 pixels; MAME and this core show 384), hsync 48 pixels starting
  21 pixels after hblank starts;
* vblank 40 lines (16 before the picture, 24 after it), vsync 8 lines starting 17 lines after vblank starts.

The picture is at x 40, y 16 of that raster (MAME's visible area is (40, 16) - (423, 239) too).

MAME's raster is not the chip's: the driver sets `set_raw(6 MHz, 384, ..., 264)` and then `set_size(512, 256)`, which
keeps the frame time (59.1856 Hz) but makes the frame 256 lines of 66 us (measured with `time_until_pos`,
`tools/lua/screen_info.lua`). Everything MAME specifies by scanline number is therefore placed at the same *time* of the
frame here, relative to the picture's first line (see `vs_core` parameters): IRQ6 (MAME line 24) at raster line 24 + a
quarter line, IRQ5 (MAME line 248) at raster line 255 + a quarter line, the frame update (vblank end, 900 us after
MAME's line 240) at raster line 261.

## 2. Custom chips

| Chip | Function | Here |
|---|---|---|
| K056832 | tilemap generator, 4 layers over a 4 x 4 grid of 64 x 32 tile pages | `K056832_BPP_5` configured, but only four planes are loaded (the fifth byte is zero); `viostorm_tile_callback`; layer offsets (-1, +1, +3, +4); the game keeps the global X / Y flips off (`regs[0]` = 0x0044 in every state dumped and in a 36,800-frame survey; Metamorphic Force uses the Y flip, the renderer supports it) |
| K055673 | sprite generator (K053246/7 family) | `K055673_LAYOUT_RNG` (4bpp), offsets (-62, -23), z codes honoured; `metamrph_sprite_callback` |
| K055555 | priority encoder / layer mixer | 4 tile layers + OBJ (SUB1 is never enabled: there is no K053250) |
| K054338 | alpha / shadow / brightness colour stage | backdrop, 3 shadow tables, 3 brightness codes, 3 mix levels |
| K053252 | CRTC / interrupt controller | timing above |
| K054321 | main <-> sound latches, master volume | as Gaiapolis |
| K055550 | memset / copy / collision list / homing vector | `rtl/k055550.sv`, section 4 |
| ER5911 | serial EEPROM | as Gaiapolis |

There is no K053250 (the 24c000 / 250000 ranges that Metamorphic Force gives it are plain RAM in MAME's map, and the
game never touches them: `tools/lua/ram_use.lua` over 3,000 frames including the power-on tests), no K053936 and no K054000.

## 3. Main CPU memory map (`viostorm_map`)

| Range | | Function |
|---|---|---|
| `000000-1FFFFF` | R | program ROM (1 MB fitted: the 15h / 15f pair of 512 KB; 100000 up reads zero) |
| `200000-20FFFF` | RW | work RAM (the stack grows down from `210000`) |
| `210000-210FFF` | RW | K053247 sprite RAM (2048 words) |
| `211000-21FFFF` | RW | plain RAM, 60 KB: the power-on test checks all of it and the game keeps its object table and collision lists in it (0x21ab00 ...) |
| `240000-240007` | W | K053246 registers |
| `244000-24400F` | R | K055673 ROM read-back (`k055673_rom_word_r`, 4bpp) |
| `244010-24401F` | W | K055673 registers |
| `24C000-25000F` | RW | plain RAM in MAME ("K053250 ram / reg"), never touched: reads 0, writes ignored here |
| `254000-25401F` | W | K054338 |
| `258000-2580FF` | W | K055555 |
| `25C000-25C03F` | RW | **K055550** (32 word registers, readable) |
| `260000-26001F` | RW | K053252 (low byte) |
| `264000` | W | sound IRQ (Z80 IRQ0) |
| `268000-26801F` | RW | K054321 (low byte) |
| `26C000-26C007`, `270000-27003F` | W | K056832 VSCCS, VACSET |
| `274000`, `274002` | R | `P1_P3`, `P2_P4` (player 1 / 2 in the low byte, 3 in the high byte of `274000`; the high byte of `274002`, MAME's player 4, is never read by the game) |
| `278000` | R | `IN0`: coins 1-3 (bits 2:0; the game masks the byte with 7, so bit 3 is dead), service 1-3 (bits 6:4; bit 6 only in 3-player mode) |
| `278002` | R | `IN1`: EEPROM DO (bit 0) / READY (bit 1), bit 2 unassigned, bit 3 test, SW1 (bits 7:4) |
| `27C000` | W | EEPROM (DI / CS / CLK on bits 0/1/2) and the watchdog |
| `300000-307FFF` | RW | K056832 tile RAM window (8 KB, mirrored x4; 16 pages behind regs[0x19]) |
| `310000-311FFF` | R | K056832 ROM read-back (`mw_rom_word_r`: 2048 groups of four chunky bytes behind regs 0x1a / 0x1b) |
| `330000-331FFF` | RW | palette, 2048 x 32 bit |

The read-back windows (`244000`, `310000`) are real windows (the power-on RAM / ROM check reads them): the K056832's
bank is `(regs[0x1a] | regs[0x1b] << 16) % 614` banks of 2048 groups; the first 512 hold the 4 MB of tile ROM (1M groups
of five bytes, the fifth never loaded), the rest read 0.

### Inputs

`P1_P3` / `P2_P4`: each byte a player: bit 0 left, 1 right, 2 up, 3 down, 4 attack, 5 jump, 6 button 3, 7 start (active
low). The game has **three players with two buttons**; what the program does with the bits (who reads the words: `tools/lua/input_reads.lua` and a disassembly; what
depends on them: `tools/lua/input_use.lua`, run by `tools/input_use.ps1`; MAME 0.289):

- The input routine (`01cfa`) reads the bytes at `274001` (P1), `274003` (P2) and `274000` (P3) and keeps, per player, the
  held bits, the previous ones, the new presses and the latched presses (`2000d0-2000e3`, copied to the player structs at
  `200800` / `200880` / `200900`). Start is handled by the coin routine (`08dce`): `andi #$80` per player, and P3's only when
  `200500` is set (the number-of-players DIP at `278003` bit 7 = 0, 3 players). Nothing reads `274002`; the coin byte is
  masked with 7 (coins 1-3) and the service bits with `$30`, or `$70` in 3-player mode: a service press adds a credit.
- The program's own I/O CHECK screen (strings at `0784ca`) has, for PLAYER 1 / 2 / 3: LEFT, RIGHT, UP, DOWN, ATTACK, JUMP,
  START, SERVICE; then COIN MECH SWITCH 1-3 and TEST SWITCH. The DIP screen says "1 PLAYER ATTACK = EXIT". There is no third
  button and no fourth player; MAME lists them because `KONAMI16_LSB` / `MSB` define a third button and the table a fourth
  player for every board of the family.
- Measured (`tools/input_use.ps1`): scripted play from the same clean state, the sprite RAM and the work RAM checksummed
  every 25 frames with the raw input bytes left out. The baseline run twice: identical. P1's button 1 or button 2 never
  pressed: the game differs from the baseline from 25 / 175 frames after the buttons start (frame 500). P1's button 3 never
  pressed (4,000 frames), or held down from frame 600 (2,500 frames, with each of Wade, Boris and Kyle, picked with the
  cursor on the select screen): identical throughout. In the service menu (test switch on) button 1 changes the program's
  state at once (it leaves the menu), button 3 of P1, P2 or P3 changes nothing. The code that tests bit 6 is the shared
  player / enemy state machine (`34b06` ...: `($2,A3)` is the controller struct of whichever object it runs for, the enemies'
  included) and a hidden combination of P2 in the test menu (`05f9e`).

## 4. The K055550 (`rtl/k055550.sv`)

MAME performs the chip's commands in zero time inside the write (`konamigx_m.cpp`, `K055550_word_w`). The chip masters
the main bus and holds the 68000 while it works here, so the program sees the result when its next instruction runs:
the homing vector's result (register 16) is read by the instruction right after the command write (`pc 03d9c6`).

Commands in 5,000 frames of scripted play (`tools/lua/k550_log.lua`, summarised by
as `tools/k550_stats.py`): 0x9f memset (4,063: 4 x 256 bytes at 0x20d400 every frame, 8 KB of the tile RAM window, whole RAM clears),
0x87 (3,826: MAME's source documents it as "unknown memory write" and does nothing; so does the chip here), 0xa0
collision list (1,387: 2 or 3 objects of 128 bytes at 0x21ab00, hit list at byte 18), 0xc0 homing vector (138). 0x98 (a
copy, the "color check" palette) is MAME's too and not seen in play.

The homing vector is `i = (floor(atan(dy / dx) * 128 / pi) [+ 128 if dx < 0] - 0x40) & 0xff` with MAME's special cases
(`dx == 0`, `dy == 0`, both 0: a random byte). The RTL finds the angle with a six-step search against 63 tangents
`tan(k pi / 128)` as 40-bit fractions (`rtl/data/tan128.hex`, `tools/gen_tan128.py`); `sim/k550_ref.cpp` compares it with
MAME's expression for all 2^32 inputs: 0 mismatches (`sim/run_k550.sh`).

## 5. Video

### Tiles (K056832, 4bpp)
As Metamorphic Force (`viostorm_tile_callback` is the same function): colour `layer colour base | (c >> 2 & 0x0f)`, a
non-zero `attr & 3` marks the tile as category 1 with that value as its mix code. Differences: layer offsets (-1, +1,
+3, +4) against Metamorphic Force's (+2, +4, +6, +7), the 384-pixel line (49 tile groups of eight, four layers: 196
fetches a line), and **the category-1 pass**, which this game uses (its fades): konamigx's `gx_draw_basic_tilemaps`
draws a layer's tiles that carry a mix code in a separate pass at the level of the *last* such code the callback has
seen (`m_last_alpha_tile_mix_code`, a persistent member), when V_INMIX_ON does not claim the layer's codes and that level
is below 255; every other tile takes the layer's internal level (V_INMIX & V_INMIX_ON). The tilemap carries each pixel's
tile code (`tmix`) and the last non-zero code fetched (`last_mix`); `vs_mixer` does the rest.

**Layer configuration.** `tools/lua/cfg_log.lua` of the Metamorphic Force core (logs every change of the K056832's flip,
tile-mode, scroll-mode and page-span registers over a MAME run) over 26,800 frames of the attract mode with its demo play
and 10,000 frames of scripted play shows one configuration after the first four frames, in both: every layer one page
high and one page wide (start rows 0 / 1 / 0 / 1, start columns 0 / 0 / 1 / 1), **xy scroll (mode 3) on all four**, no X
or Y flip (`regs[0]` bits 5:4 clear), `regs[0]` = 0x0044. This game does not use the line or row scroll modes or layers taller than one page, so the
renderer's handling of those (`k056832_tilemap.sv` flags the combinations it has not been checked for as `unsupported`)
is not reached. It matters for the Metamorphic Force Hall of Fame screen, where the same renderer drew a two-page row
scroll layer with the wrong entries until 20261014; that fix is not in this core.

The renderer's 16-bit tile codes address the first 2 MB of the 4 MB tile ROM only (MAME's callback does not extend
them); the other half is reachable through the read-back window. The tilemap's ROM rows come through a 512-entry
direct-mapped row cache (`spr_rowcache` with the tile ROM's geometry): 86% of a frame's fetches hit a 64-entry one, and
that is what keeps four layers of 49 tiles inside the 6,144-clock line at SDRAM latencies of 34 clocks and above.

### Sprites (K055673 RNG layout, 4bpp)
As Metamorphic Force; offsets (-62, -23). 8 MB sprite ROM, a 64-bit word a 16-pixel row.

### Mixer
`konamigx_mixer` (K055555 + K054338) as Metamorphic Force's, with one change forced by the pixel clock: the blending
pipeline of the mixer needs 16 clocks a pixel and an 8 MHz pixel is 12 clocks of the 96 MHz clock, so `vs_mixer` runs two
cores on alternate pixels (24 clocks each) and returns a pixel's colour one pixel period late; `vs_core` delays de /
sync by the same amount.

### Interrupts and timing
`metamrph_interrupt` as Metamorphic Force: IRQ6 (`HOLD_LINE`) at MAME line 24, IRQ5 at line 248 when the K053246's register
5 bit 4 is set. See section 1 for where those are in this raster.

## 6. Sound

As Gaiapolis (`docs/hardware.md` of that core): Z80 with ROM banks at `8000-BFFF` (regs `F800` bits 3:0), the
K054539s at `E000-E22F` and `E400-E62F`, K054321 at `F000-F003`, timer NMI gated by `F800` bit 4. `MACHINE_RESET
viostorm`: chip 1 channels 4-7 at x2.0 (as `dadandrn`), everything else x1.0. The chip replay bench
(`sim/run_k539.sh`, MAME's register log and `-wavwrite` of 70 s of play) correlates 0.92-0.98 a second with MAME's stream
at the lag found by a cross-correlation (-559 samples here).

## 7. Tools

| | |
|---|---|
| MAME | 0.289, `C:\repos\taitol-mister\mister\tools\mame\mame.exe` (`tools/mame_run.ps1`) |
| ROMs | `R:\Games\Arcade\MAME 0.289 ROMs (merged)\viostorm.zip` |
| Verilator | 5.053 (oss-cad-suite in WSL) |
| Quartus | 17.0.2 Lite |
