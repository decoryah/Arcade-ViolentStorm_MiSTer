#!/usr/bin/env python3
"""Writes the seven Violent Storm MRAs (mra/*.mra) from a MAME viostorm.zip.

The image layout is the one target/mister/vs_mem.sv loads (docs/mister-memory.md):
the regions in the order below, 0x1240000 bytes. The default EEPROM is a
separate download (index 2): the HPS then also saves and restores it
(<nvram index="2">), so the game's settings and records persist.

    python tools/make_mra.py "/path/to/MAME 0.289 ROMs (merged)/viostorm.zip"
"""
import sys, zipfile, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vs_rom

SETS = [
    # setname, title, region, nvram file inside the zip
    ("viostorm",   "Violent Storm (World ver EAC)",  "World", "viostorm.nv"),
    ("viostormeb", "Violent Storm (World ver EAB)",  "World", "viostormeb/viostormeb.nv"),
    ("viostormu",  "Violent Storm (USA ver UAC)",    "USA",   "viostormu/viostormu.nv"),
    ("viostormub", "Violent Storm (USA ver UAB)",    "USA",   "viostormub/viostormub.nv"),
    ("viostormj",  "Violent Storm (Japan ver JAC)",  "Japan", "viostormj/viostormj.nv"),
    ("viostorma",  "Violent Storm (Asia ver AAC)",   "Asia",  "viostorma/viostorma.nv"),
    ("viostormab", "Violent Storm (Asia ver AAB)",   "Asia",  "viostormab/viostormab.nv"),
]
CRC = {k: "%08x" % v for k, v in vs_rom.CRC.items()}


def hexdump(data):
    lines = []
    for i in range(0, len(data), 16):
        lines.append(" ".join("%02X" % b for b in data[i:i + 16]))
    return "\n".join(lines)


def mra(setname, title, region, nvdata):
    p1, p0 = vs_rom.SETS[setname]            # 15h = odd bytes, 15f = even bytes
    return f"""<misterromdescription>
    <rotation>horizontal</rotation>
    <name>{title}</name>
    <setname>{setname}</setname>
    <mameversion>0289</mameversion>
    <year>1993</year>
    <manufacturer>Konami</manufacturer>
    <players>4</players>
    <joystick>8</joystick>
    <rbf>violentstorm</rbf>
    <region>{region}</region>
    <platform>Konami pre-GX</platform>

    <!--
      Flat image for the Violent Storm core (target/mister/vs_mem.sv):

        0x0000000  0x200000  68000 program: 2 x 512 KB at 0 (the map's 2 MB; 0x100000 up is zero)
        0x0200000  0x040000  Z80 sound program: 168a05.7c twice, 16 x 16 KB banks
        0x0240000  0x400000  K056832 tile ROM, 4bpp: per 8-pixel row 4 chunky bytes
                             (the board's fifth plane is not populated)
        0x0640000  0x400000  K054539 PCM (2 x 2 MB)
        0x0A40000  0x800000  K055673 sprite ROM, 64-bit words: a 16-pixel row of the four planes
        0x1240000            end

      Expects the MAME 0.289 merged romset (viostorm.zip holding the parent and the
      clones) or the split sets: parts are found by name, whatever folder holds them.
    -->
    <rom index="0" zip="{setname}.zip|viostorm.zip" md5="None" address="0x32000000">

        <!-- 68000 program, 16-bit big-endian words: the even byte is the 15f half, the odd byte the 15h half -->
        <interleave output="16">
            <part name="{p0}" crc="{CRC[p0]}" map="01"/>
            <part name="{p1}" crc="{CRC[p1]}" map="10"/>
        </interleave>
        <part repeat="0x100000">00</part>

        <!-- Z80 sound program: ROM_LOAD + ROM_RELOAD, the 128 KB twice -->
        <part name="168a05.7c" crc="{CRC['168a05.7c']}"/>
        <part name="168a05.7c" crc="{CRC['168a05.7c']}"/>

        <!--
          K056832 tile ROM. MAME's ROM_LOADTILE_WORD is ROM_GROUPWORD|ROM_SKIP(3)|ROM_REVERSE: 5-byte
          groups, one per 8-pixel row, of which this game loads the four packed-chunky bytes (the low 4
          bits of each pixel); the fifth plane's byte is empty (ROMREGION_ERASE00).
        -->
        <interleave output="32">
            <part name="168a09.1h" crc="{CRC['168a09.1h']}" map="0012"/>
            <part name="168a08.1k" crc="{CRC['168a08.1k']}" map="1200"/>
        </interleave>

        <!-- K054539 PCM samples, shared by both chips -->
        <part name="168a06.1c" crc="{CRC['168a06.1c']}"/>
        <part name="168a07.1e" crc="{CRC['168a07.1e']}"/>

        <!--
          K055673 sprite ROM, 64-bit words (ROM_LOAD64_WORD, 8-byte stride): one 64-bit word
          is the four planes of one 16-pixel row (left 8 pixels in bytes 0-3, right 8 in
          bytes 4-7, one byte a plane): K055673_LAYOUT_RNG.
        -->
        <interleave output="64">
            <part name="168a10.22k" crc="{CRC['168a10.22k']}" map="00000021"/>
            <part name="168a11.19k" crc="{CRC['168a11.19k']}" map="00002100"/>
            <part name="168a12.20k" crc="{CRC['168a12.20k']}" map="00210000"/>
            <part name="168a13.17k" crc="{CRC['168a13.17k']}" map="21000000"/>
        </interleave>
    </rom>

    <!-- the board's factory EEPROM: without it the game boots upside down with an error -->
    <rom index="2">
        <part>
{hexdump(nvdata)}
        </part>
    </rom>
    <nvram index="2" size="128"/>

    <buttons names="Button 1,Button 2,Button 3,Start,Coin" default="A,B,R,Start,Select" count="3"/>
</misterromdescription>
"""


def main():
    if len(sys.argv) < 2:
        print(__doc__); return 2
    z = zipfile.ZipFile(sys.argv[1])
    names = {}
    for i in z.infolist():
        names.setdefault(os.path.basename(i.filename), []).append(i)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "mra")
    os.makedirs(out, exist_ok=True)
    for base, want in CRC.items():
        if base in names and not any(("%08x" % i.CRC) == want for i in names[base]):
            raise SystemExit("%s: no copy with crc %s" % (base, want))
    for setname, title, region, nv in SETS:
        info = z.getinfo(nv)
        data = z.read(nv)
        assert len(data) == 128, (nv, len(data))
        for n in vs_rom.SETS[setname]:
            assert any(("%08x" % i.CRC) == CRC[n] for i in names[n]), (n, CRC[n])
        path = os.path.join(out, title + ".mra")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(mra(setname, title, region, data))
        print("wrote", os.path.normpath(path), "(nvram crc %08x)" % info.CRC)


if __name__ == "__main__":
    sys.exit(main())
