## Violent Storm for MiSTer - 20261025

Konami's **Violent Storm** (1993, GX168 "pre-GX" hardware), the three-player beat-'em-up, with seven MRAs: World (EAC, EAB), USA (UAC, UAB), Japan (JAC) and Asia (AAC, AAB).

### What's new since 20261024

- **Fades and fireworks like the real board.** A new OSD option, **Sprite effects: PCB / MAME** (PCB is the default).
  - The game fades out and in at every stage change and every attract demo, and draws the stage-clear fireworks, with sprites of shadow code 3: every pixel of them darkens (or, for the fireworks, lights up in a colour that changes from burst to burst) what lies under it. MAME 0.289 skips these sprites: no fade (full brightness, then a cut to black) and no fireworks. With *PCB* the playfield, the characters and the HUD fade while the stage map stays bright, and the fireworks go off at the end of stage 2, as in a recording of a real PCB.
  - A shadow no longer falls on a sprite of its own priority or higher, so a character's floor shadow does not darken another character beside it (MAME darkens it; the PCB recording does not).
  - *MAME* gives exactly the picture of 20261024, pixel for pixel.
  - Found by a patched MAME someone made for this game (five changes); three are in. One rule is copied from it without a known hardware reason: the game keeps two of its fade sprites parked over the right half of the screen through stage 2, and they are not drawn while the fireworks use their shadow table (otherwise the right half takes the fireworks' colour, which the board does not show). Not in: the patch's opaque black shadow pens and its rounding of zoomed sprites' positions.
- Nothing else changed: controls, colours, sound and loading are as in 20261024.

### Install

1. Unzip `ViolentStorm_MiSTer_20261025.zip` over the root of the SD card. It adds the MRAs to `_Arcade/` and `_Arcade/cores/violentstorm_20261025.rbf`.
2. Put your own MAME 0.289 romset `viostorm.zip` in `games/mame/`. The merged set holds all versions; the clone zips (`viostormu.zip`, `viostormj.zip`, `viostorma.zip` and so on) work next to the parent. No ROMs are included. The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.
3. Delete older `violentstorm_*.rbf` files from `_Arcade/cores/`.
4. Coming from 20261014 or earlier: use the MRAs from this zip and map the buttons once more (the controls changed in 20261022). Fast loading needs a recent Main_MiSTer; an older one loads at the old speed.

The OSD's version line reads `v261025`. The build: Quartus Prime Lite 17.0.2, 20,556 ALMs (49 %), 537 / 553 M10K, 74 / 112 DSP, every timing check positive (setup +0.28 ns on the 96 MHz core clock, hold +0.24 ns at the tightest).

### Checked

- **On a real MiSTer:** 20261012, 20261013, 20261014, 20261022 and 20261024 were tested by the repository owner and work; 20261025 was tested the same way and works.
- **In simulation:**
  - Sprite effects = MAME: the 86 frames compared with MAME 0.289 and 15 more (the stage-2 clear's fireworks and fade, the stage-2 train roof) still pixel-identical.
  - Sprite effects = PCB: at the stage-2 clear no right-half tint, the fireworks, and the fade dimming everything but the map (as the PCB recording and the patched MAME show it); on the train roof the floor shadows on both halves of the screen; of the 86 frames only 9 attract-demo frames differ from MAME, by 18 to 292 pixels each, where a floor shadow no longer covers a character.
  - The whole MiSTer top level, 90 frames after a fast load: with both settings byte-identical to 20261024, the picture's position against the syncs unchanged.

### OSD

Aspect ratio, Scale, Flip Screen, Scandoubler Fx, Colours, **Sprite effects**, CRT Adjust (rmonic79's module: H-Size, H-Position, V-Shift), Number of Players (2 or 3), Coin Mechanism, Audio (stereo / mono), Test Mode, Diagnostic overlay, SDRAM read capture, Reset. See the README.

### Known differences from MAME

- Sprite effects: with the default (PCB) the fades, the fireworks and the shadows' priority follow the board, not MAME; Sprite effects = MAME gives MAME's. While a fade runs, a character's floor shadow gives way to the fade's darkening (one shadow a pixel).
- Colours: with the default Colours = Board DAC the picture follows the board's video DACs, not MAME's linear palette; Colours = MAME gives MAME's.
- The K055550 takes real time here (it holds the 68000 while a command runs); MAME's commands are instant. The game reads the results only after the command, so it sees MAME's values.
- Later stages, the bosses and the service menu are not in the comparison corpus yet, so they are the least checked part.

### Credits

plasticbugs' Gaiapolis core for the Analogue Pocket (the machine the Metamorphic Force and Monster Maulers cores, and so this one, are built on); the repository owner's Gaiapolis core (the 054573 model behind Board DAC) and Metamorphic Force core (fast loading and Scale); the author of the patched MAME behind Sprite effects (shadow code 3, the shadow priority test); **Ace**'s Gerbers and BOM of the K054573 / K054574 reproductions (the circuit), **Franck78**'s Konami Gaiapolis schematic (the video DAC chain) and **furrtek**'s SiliconRE (the K054338 trace; the K053252 raster model); **BB4**'s recording of a real Violent Storm PCB, "VIOLENT STORM Arcade Real Hardware Framemeister + OSSC" (https://www.youtube.com/watch?v=0hEZvGd4whM), that the colours are fitted to and the sprite effects were checked against; MAME, TG68K.C, tv80, rmonic79's CRT Adjust, Jose Tejada's JTFRAME SDRAM timing notes, jlrh's konami-fpga and ppriest's Arcade-KonamiGX_MiSTer as references, and the MiSTer framework.

---

### Forum post changelog

```
20261025
- Fades and fireworks like the real board: new OSD option Sprite effects, PCB (default) /
  MAME. PCB draws the game's fades between scenes (the stage map stays bright) and the
  stage-clear fireworks, which MAME skips, and keeps floor shadows off other characters.
  MAME gives the old picture exactly. Nothing else changed.

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
