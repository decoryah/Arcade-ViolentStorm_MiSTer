## Violent Storm for MiSTer - 20261014

Konami's **Violent Storm** (1993, GX168 "pre-GX" hardware), the three-player beat-'em-up, with seven MRAs: World (EAC, EAB), USA (UAC, UAB), Japan (JAC) and Asia (AAC, AAB).

### What's new since 20261013

- **Fast loading.** The ROM image now loads in about a second instead of tens of seconds. The MRAs carry `address="0x32000000"` on the ROM image: a recent Main_MiSTer copies the whole assembled image into the DDR3 in one go and the core reads it back from there into its loader. It needs a **recent Main_MiSTer**; an older one ignores the attribute and just loads at the old speed, with the same RBF and MRAs. **Use the MRAs from the zip** (the attribute is in them). The game's own power-on RAM / ROM check afterwards is unchanged (about 14 s, as on the board).
- **Scale option in the OSD:** Normal, V-Integer, HV-Integer, Narrower HV-Integer, HV-Integer+ (integer scaling for the HDMI scaler; the 15 kHz analog output is not touched). Normal leaves the picture's size to the scaler, as before. Full Screen with an integer Scale is given the screen's own proportions, so it is the largest whole-number picture in the screen's aspect.
- Nothing else changed. The 15 kHz picture and timing are byte-identical to 20261013's in simulation.

Both come from the Metamorphic Force core (its 20261013 release).

### Install

1. Unzip `ViolentStorm_MiSTer_20261014.zip` over the root of the SD card. It adds the MRAs to `_Arcade/` and `_Arcade/cores/violentstorm_20261014.rbf`.
2. Put your own MAME 0.289 romset `viostorm.zip` in `games/mame/`. The merged set holds all versions; the clone zips (`viostormu.zip`, `viostormj.zip`, `viostorma.zip` and so on) work next to the parent. No ROMs are included. The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.
3. Delete older `violentstorm_*.rbf` files from `_Arcade/cores/`.
4. Start the game from the Arcade menu. To see which load you got, switch on the Diagnostic overlay: the *download* square is lit for about a second with fast loading and for the whole, much longer streamed load without.

The OSD's version line reads `v261014`. The build: Quartus Prime Lite 17.0.2, 20,466 ALMs (49 %), 520 / 553 M10K, 74 / 112 DSP, every timing check positive (setup +0.27 ns on the 96 MHz core clock, hold +0.20 ns at the tightest).

### Checked

- **In simulation** (the whole MiSTer top level, `sim/emu`):
  - Fast load: the image replayed from a DDR3 model in 0.805 s of simulated time (77.26 million clocks at 96 MHz; the loader's rate is the limit), every one of the 9,568,256 words where the memory ports read it, 0 wrong, 74,752 block reads, 0 DDR3 protocol errors. The core comes out of reset on its own, and 90 frames later the frame periods (89 of 89 whole), the geometry and the scaler picture are byte-identical to the streamed load's and to 20261013's.
  - The built-in memory test (Diagnostic overlay on) runs to its end after a fast load and after a streamed one with every region read back ok and stable.
  - Scale: the size the core asks the scaler for, compared with the framework's integer rule worked out independently in the bench, over the five Scale modes, three aspect settings and six scaler sizes (1920 x 1080, 1280 x 720, 3840 x 2160, 640 x 480, 200 x 150 and an unknown size) on the 15 kHz path, and with the forced scandoubler and HQ2x at 1920 x 1080: 120 runs, none off. For example, at 1920 x 1080 with 4:3: V-Integer 1194 x 896, HV-Integer and Narrower HV-Integer 1152 x 896, HV-Integer+ 1536 x 896.
- **On a real MiSTer:** 20261012 and 20261013 were tested by the repository owner and work; 20261014 was too: the game, fast loading and the Scale options work.
- Everything 20261013 was checked for (against MAME 0.289) is unchanged: 86 of 86 frozen frames pixel-identical, the K055550 against MAME's code, the sound chips against MAME's log.

### OSD

Aspect ratio, **Scale**, Flip Screen, Scandoubler Fx, CRT Adjust (rmonic79's module: H-Size, H-Position, V-Shift), Number of Players (2 or 3), Coin Mechanism, Audio (stereo / mono), Test Mode, Diagnostic overlay, SDRAM read capture, Reset. See the README.

### Known differences from MAME

- The K055550 takes real time here (it holds the 68000 while a command runs); MAME's commands are instant. The game reads the results only after the command, so it sees MAME's values.
- Later stages, the bosses and the service menu are not in the comparison corpus yet, so they are the least checked part.

### Credits

plasticbugs' Gaiapolis core for the Analogue Pocket (the machine the Metamorphic Force and Monster Maulers cores, and so this one, are built on), the Metamorphic Force core (fast loading and Scale), MAME, TG68K.C, tv80, rmonic79's CRT Adjust, Jose Tejada's JTFRAME SDRAM timing notes, jlrh's konami-fpga and ppriest's Arcade-KonamiGX_MiSTer as references, and the MiSTer framework.

---

### Forum post changelog

```
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
