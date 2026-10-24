## Violent Storm for MiSTer - 20261024

Konami's **Violent Storm** (1993, GX168 "pre-GX" hardware), the three-player beat-'em-up, with seven MRAs: World (EAC, EAB), USA (UAC, UAB), Japan (JAC) and Asia (AAC, AAB).

### What's new since 20261022

- **Colours like the real board.** A new OSD option, **Colours: Board DAC / MAME** (Board DAC is the default).
  - The board does not show the palette's values as they are: each colour channel goes through a Konami 054573 video DAC whose output rises faster near the top, so mid tones are darker than MAME shows them. And the game fades every screen with a brightness that dims those DACs after the colours are mixed, where MAME scales the colours before mixing.
  - *Board DAC* does what the board does: the colours are mixed at full brightness, and one table turns each colour and its brightness into the output (the 054573 circuit as the Gaiapolis core traced it from Ace's reproduction board, fitted to BB4's recording of a real Violent Storm PCB, https://www.youtube.com/watch?v=0hEZvGd4whM).
  - *MAME* gives exactly the picture of 20261022, pixel for pixel.
  - Against the PCB recording (VER. EAB; the capture chain's gain and offset fitted out): on five still screens MAME's colours are 12.9 levels rms (of 255) from the board and Board DAC 3.7; on the player select's fade-out MAME's colours are 24.9 from the board, Board DAC 12.7 (the still frames themselves: about 10), and the same curve applied after MAME's fade would be 29.5.
- Nothing else changed: controls, sound and loading are as in 20261022.

### Install

1. Unzip `ViolentStorm_MiSTer_20261024.zip` over the root of the SD card. It adds the MRAs to `_Arcade/` and `_Arcade/cores/violentstorm_20261024.rbf`.
2. Put your own MAME 0.289 romset `viostorm.zip` in `games/mame/`. The merged set holds all versions; the clone zips (`viostormu.zip`, `viostormj.zip`, `viostorma.zip` and so on) work next to the parent. No ROMs are included. The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.
3. Delete older `violentstorm_*.rbf` files from `_Arcade/cores/`.
4. Coming from 20261014 or earlier: use the MRAs from this zip and map the buttons once more (the controls changed in 20261022). Fast loading needs a recent Main_MiSTer; an older one loads at the old speed.

The OSD's version line reads `v261024`. The build: Quartus Prime Lite 17.0.2, 20,446 ALMs (49 %), 537 / 553 M10K (the colour table takes 16), 74 / 112 DSP, every timing check positive (setup +0.36 ns on the 96 MHz core clock, hold +0.25 ns at the tightest).

### Checked

- **On a real MiSTer:** 20261012, 20261013, 20261014 and 20261022 were tested by the repository owner and work; 20261024 was tested the same way, and the owner reports the colours are right.
- **In simulation:**
  - The colour stage against its table: every colour code at every brightness step, plus 100,000 random pixels with the mode switching, 120,480 pixels, 0 wrong (a copy with red and green swapped fails 58,362).
  - The 86 frames compared with MAME 0.289: with Colours = MAME still 86 of 86 pixel-identical; in Board DAC mode the mix is the same at full brightness (all 86 frames are) and the brightness passed on is 255 everywhere.
  - Four MAME states in the middle of fades: MAME's colours identical to MAME's snapshots; Board DAC's mix identical to the same state at full brightness, with the brightness the game's register has.
  - The whole MiSTer top level, 90 frames after a fast load: Colours = MAME byte-identical to the earlier builds, Board DAC exactly that picture through the curve, the picture's position against the syncs unchanged.

### OSD

Aspect ratio, Scale, Flip Screen, Scandoubler Fx, **Colours**, CRT Adjust (rmonic79's module: H-Size, H-Position, V-Shift), Number of Players (2 or 3), Coin Mechanism, Audio (stereo / mono), Test Mode, Diagnostic overlay, SDRAM read capture, Reset. See the README.

### Known differences from MAME

- Colours: with the default Colours = Board DAC the picture follows the board's video DACs, not MAME's linear palette; Colours = MAME gives MAME's.
- The K055550 takes real time here (it holds the 68000 while a command runs); MAME's commands are instant. The game reads the results only after the command, so it sees MAME's values.
- Later stages, the bosses and the service menu are not in the comparison corpus yet, so they are the least checked part.

### Credits

plasticbugs' Gaiapolis core for the Analogue Pocket (the machine the Metamorphic Force and Monster Maulers cores, and so this one, are built on); the repository owner's Gaiapolis core (the 054573 model behind Board DAC) and Metamorphic Force core (fast loading and Scale); **Ace**'s Gerbers and BOM of the K054573 / K054574 reproductions (the circuit), **Franck78**'s Konami Gaiapolis schematic (the video DAC chain) and **furrtek**'s SiliconRE (the K054338 trace; the K053252 raster model); **BB4**'s recording of a real Violent Storm PCB, "VIOLENT STORM Arcade Real Hardware Framemeister + OSSC" (https://www.youtube.com/watch?v=0hEZvGd4whM), that the colours are fitted to; MAME, TG68K.C, tv80, rmonic79's CRT Adjust, Jose Tejada's JTFRAME SDRAM timing notes, jlrh's konami-fpga and ppriest's Arcade-KonamiGX_MiSTer as references, and the MiSTer framework.

---

### Forum post changelog

```
20261024
- Colours like the real board: new OSD option Colours, Board DAC (default) / MAME. Board DAC
  follows the board's video DACs: darker mid tones, and the fades done in the DACs as on the
  PCB (fitted to BB4's recording of a real board). MAME gives the old picture exactly.
  Nothing else changed.

20261022
- Controls match the cabinet: three players, two buttons. The mapping dialog lists Attack, Jump,
  Start, Coin (was Button 1-3); the unused third button and fourth joystick are gone (the game
  never reads them). Use the MRAs from the zip and map the buttons once more.
  Nothing else changed.

20261014
- Fast loading: the ROM now loads in about 1 s instead of tens of seconds. It needs a recent
  Main_MiSTer; an older one just loads at the old speed. Use the MRAs from the zip.
- Scale option in the OSD: Normal, V-Integer, HV-Integer, Narrower HV-Integer, HV-Integer+
  (integer scaling for HDMI).

20261013
- Fixed: no vertical sync (a frozen picture, sound only) with Scandoubler Fx or MiSTer.ini's
  forced_scandoubler in 20261012. The 15 kHz and direct video outputs are unchanged.

20261012
- First release: 7 MRAs (World, USA, Japan, Asia), three players, CRT Adjust, Flip Screen.

Download and source: https://github.com/decoryah/Arcade-ViolentStorm_MiSTer
You need your own MAME 0.289 viostorm.zip.
```
