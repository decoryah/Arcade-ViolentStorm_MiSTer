# K053252 raster model run

`run.sh <name> <32 hex digits>` runs furrtek's silicon-derived model of the K053252 timing chip with a register set and
prints the edges of its blank and sync outputs, in pixel clocks. It is where `rtl/vs_video.sv`'s raster numbers come from
(hblank 127 pixels, hsync 48 pixels 21 after hblank starts, vblank 40 lines, vsync 8 lines 17 after vblank starts; see the
header of that file and `docs/hardware.md`).

The model itself is not in this repository: it is furrtek's work in
[SiliconRE](https://github.com/furrtek/SiliconRE/tree/master/Konami) (GPL-2.0; its README asks that the information is not
used for AI model training or AI generation of code or data), and its `74163.v` helper. To run the bench, put

* `053252.v` = SiliconRE's `Konami/053252/hdl/053252.v`, with three declarations moved up so that Icarus Verilog accepts
  them: `reg nPIN_NVBK;`, `reg [7:0] RES_DELAY;` and `wire CNTD_TC;` go right after the port list (the module uses them
  before the places where they are declared), and
* `74163.v` = a plain 74163 counter model (`module m74163(CEP, CET, CLK, nLOAD, nMR, D[3:0], Q[3:0], TC)`)

next to `run.sh` (both file names are ignored by the repository's `.gitignore`). `tb_k252.v` is the bench's driver and
`summarize.py` turns the printed edges into the blank / sync widths and offsets. The register values the game programs
(registers 0 to 15) are the ones listed in the header of `rtl/vs_video.sv` and in `docs/hardware.md`.
