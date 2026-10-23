## Violent Storm for MiSTer - 20261022

Konami's **Violent Storm** (1993, GX168 "pre-GX" hardware), the three-player beat-'em-up, with seven MRAs: World (EAC, EAB), USA (UAC, UAB), Japan (JAC) and Asia (AAC, AAB).

### What's new since 20261014

- **The controls match the cabinet.** The button-mapping dialog said *Button 1, Button 2, Button 3, Start, Coin*; it now lists **Attack, Jump, Start, Coin**, the names on the game's own I/O CHECK screen. Violent Storm has **three players with two buttons each**:
  - The program never reads a fourth player (the input byte MAME lists for player 4 is not read anywhere in the ROM), its I/O CHECK screen has three player columns, and the coin byte is masked to three coins.
  - There is no third button: the I/O CHECK screen lists ATTACK and JUMP only, and in MAME a third button held down for 2,500 frames of play with each of Wade, Boris and Kyle (and in the service menu, for players 1-3) changes nothing in the game's memory or picture, while button 1 or 2 left unpressed changes the game within 175 frames. (MAME's port list shows a third button and a fourth player because Konami's shared input macro defines them.)
  - So the third button, the fourth joystick and the keyboard's 4 (start) and 8 (coin) are gone. Keyboard: 1-3 start, 5-7 coin, F2 test switch. Gamepad default: A = Attack, B = Jump, Start = Start, Select = Coin.
- **Use the MRAs from this zip, and map the buttons once more.** Start and Coin moved down one place in the controller's bits, so an older MRA with this RBF would put Start on the wrong button, and a mapping saved for an earlier build no longer fits. Redo *Define joystick buttons* from the OSD; if the old mapping keeps coming back, delete the saved mapping file of the game in `/media/fat/config/inputs/`.
- The new README says "three-player"; the earlier notes said four-player, which was wrong.
- Nothing else changed: the diff of the machine is the input decode (the new `rtl/vs_inputs.sv`) and comments. Video, sound, loading and the OSD options are as in 20261014.
- Not mapped yet: the game's per-player **Service** buttons (each adds a credit; MAME's 9 / 0 / - keys).

### Install

1. Unzip `ViolentStorm_MiSTer_20261022.zip` over the root of the SD card. It adds the MRAs to `_Arcade/` and `_Arcade/cores/violentstorm_20261022.rbf`.
2. Put your own MAME 0.289 romset `viostorm.zip` in `games/mame/`. The merged set holds all versions; the clone zips (`viostormu.zip`, `viostormj.zip`, `viostorma.zip` and so on) work next to the parent. No ROMs are included. The two bootlegs in MAME (`viostormubbl`, `viostormabbl`) are not supported.
3. Delete older `violentstorm_*.rbf` files from `_Arcade/cores/`.
4. Start the game from the Arcade menu and map the buttons (see above). Fast loading needs a recent Main_MiSTer, as in 20261014; an older one loads at the old speed.

The OSD's version line reads `v261022`. The build: Quartus Prime Lite 17.0.2, 20,326 ALMs (48 %), 520 / 553 M10K, 74 / 112 DSP, every timing check positive (setup +0.21 ns on the 96 MHz core clock, hold +0.23 ns at the tightest).

### Checked

- **On a real MiSTer:** 20261012, 20261013 and 20261014 were tested by the repository owner and work; 20261022 was tested the same way.
- **In simulation:**
  - The new input decode against the decode of 20261014 (on the old pad layout) and against a table written from the cabinet's names: every value of every controller and key, plus a million random vectors, 1,049,177 checks, 0 mismatches. A copy with attack and jump swapped fails 899,289 of them.
  - The whole MiSTer top level (`sim/emu`, `JOYTEST`): each of the 32 bits of the four controllers pressed alone gives exactly the one board input bit the cabinet has for it (the fourth controller and the bits above the buttons give none): 128 presses, 0 wrong.
  - The input facts above, from MAME 0.289 (`tools/input_use.ps1`): runs from the same state, the baseline twice identical.
  - Not re-run for this build: the whole-machine video, sound and loading checks of 20261014 (the machine is unchanged apart from the input words, see above).

### OSD

Aspect ratio, Scale, Flip Screen, Scandoubler Fx, CRT Adjust (rmonic79's module: H-Size, H-Position, V-Shift), Number of Players (2 or 3), Coin Mechanism, Audio (stereo / mono), Test Mode, Diagnostic overlay, SDRAM read capture, Reset. See the README.

### Known differences from MAME

- The K055550 takes real time here (it holds the 68000 while a command runs); MAME's commands are instant. The game reads the results only after the command, so it sees MAME's values.
- Later stages, the bosses and the service menu are not in the comparison corpus yet, so they are the least checked part.
- The Service buttons are not mapped.

### Credits

plasticbugs' Gaiapolis core for the Analogue Pocket (the machine the Metamorphic Force and Monster Maulers cores, and so this one, are built on), the Metamorphic Force core (fast loading and Scale), MAME, TG68K.C, tv80, rmonic79's CRT Adjust, Jose Tejada's JTFRAME SDRAM timing notes, jlrh's konami-fpga and ppriest's Arcade-KonamiGX_MiSTer as references, and the MiSTer framework.

---

### Forum post changelog

```
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
