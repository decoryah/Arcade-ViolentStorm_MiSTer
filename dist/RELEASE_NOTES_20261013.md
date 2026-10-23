## Violent Storm for MiSTer - 20261013

Konami's **Violent Storm** (1993, GX168 "pre-GX" hardware), the three-player beat-'em-up, with seven MRAs: World (EAC, EAB), USA (UAC, UAB), Japan (JAC) and Asia (AAC, AAB).

**Fixed since 20261012:** **Scandoubler Fx (HQ2x, the CRT filters) and MiSTer.ini's `forced_scandoubler` no longer freeze the picture.** With the scandoubler on, 20261012 produced no vertical sync: the monitor or the HDMI scaler saw a stream without frames, the sound played and the picture stood still (31.5 kHz in MiSTer's video info). The core's horizontal blank was high through the whole vertical blank, and the framework's scandoubler needs it to toggle on every line. It now gets the horizontal blank alone, with the vertical blank separate. The 15 kHz analog and Direct Video outputs were never affected; their picture is byte-identical to 20261012's in simulation. Nothing else changed.

### Install

1. Unzip `ViolentStorm_MiSTer_20261013.zip` over the root of the SD card. It adds the MRAs to `_Arcade/` and `_Arcade/cores/violentstorm_20261013.rbf`.
2. Put your own MAME 0.289 romset `viostorm.zip` in `games/mame/`. The merged set holds all versions; the clone zips (`viostormu.zip`, `viostormj.zip`, `viostorma.zip` and so on) work next to the parent. No ROMs are included. The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.
3. Delete older `violentstorm_*.rbf` files from `_Arcade/cores/`.
4. Start the game from the Arcade menu. The ROM image is about 18 MB and takes a few seconds to load; the game's own power-on RAM / ROM check then runs for about 14 s, as on the board.

The OSD's version line reads `v261012` in this build: the framework stamps the day the core was compiled, and this one was compiled the day 20261012 was. The file name, `violentstorm_20261013.rbf`, is what tells the two builds apart.

### Checked

- **On a real MiSTer:** 20261012, the first build, was tested by the repository owner and the game worked in all areas. 20261013 was tested the same way: it works, the scandoubler modes and the 15 kHz output included.
- **In simulation, against MAME 0.289:**
  - 86 of 86 frozen frames are pixel-identical (attract mode, scripted play, and the attract mode's demo play of the later stages up to frame 26,800), also with SDRAM latencies of 48 / 34 clocks and no late line.
  - The K055550 helper chip: 1,660 random commands match MAME's code with no difference, and the homing vector matches for all 2^32 inputs.
  - The sound chips replayed from MAME's register log follow MAME's own output (correlation 0.92 to 0.98 each second).
  - The whole machine, from reset through the power-on check, shows the same picture as MAME at the frames compared.
- **The scandoubler fix:** the raster into the framework's `arcade_video` gives 528 lines a frame, 448 picture rows of 384 pixels (768 with HQ2x), a 3,072-clock line and an exact frame period (59.1856 Hz) in every Scandoubler mode; the old wiring gave no vertical sync at all. The whole top level with the forced scandoubler gives the same, with the 15 kHz picture's rows each shown twice, byte for byte.

### OSD

Aspect ratio, Flip Screen, Scandoubler Fx, CRT Adjust (rmonic79's module: H-Size, H-Position, V-Shift), Number of Players (2 or 3), Coin Mechanism, Audio (stereo / mono), Test Mode, Diagnostic overlay, SDRAM read capture, Reset. See the README.

### Known differences from MAME

- The K055550 takes real time here (it holds the 68000 while a command runs); MAME's commands are instant. The game reads the results only after the command, so it sees MAME's values.
- Later stages, the bosses and the service menu are not in the comparison corpus yet, so they are the least checked part.

### Credits

plasticbugs' Gaiapolis core for the Analogue Pocket (the machine the Metamorphic Force and Monster Maulers cores, and so this one, are built on), MAME, TG68K.C, tv80, rmonic79's CRT Adjust, furrtek's SiliconRE (the K053252 raster model), Jose Tejada's JTFRAME SDRAM timing notes, jlrh's konami-fpga and ppriest's Arcade-KonamiGX_MiSTer as references, and the MiSTer framework.

---

### Forum post changelog

```
20261013
- Fixed: no vertical sync (a frozen picture, sound only) with Scandoubler Fx or MiSTer.ini's
  forced_scandoubler in 20261012. The 15 kHz and direct video outputs are unchanged.
  (The OSD still shows v261012: that is the compile date.)

20261012
- First release: 7 MRAs (World, USA, Japan, Asia), three players, CRT Adjust, Flip Screen.

Download and source: https://github.com/decoryah/Arcade-ViolentStorm_MiSTer
You need your own MAME 0.289 viostorm.zip.
```
