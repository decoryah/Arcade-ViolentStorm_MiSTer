#!/usr/bin/env python3
"""MAME's memory regions for Violent Storm, rebuilt byte for byte from a romset, and
the check that an image built from an .mra (tools/mra_build.py) holds them in the
layout target/mister/vs_mem.sv expects.

The regions follow ROM_START( viostorm ) in MAME 0.289 src/mame/konami/mystwarr.cpp:

    maincpu    0x200000   ROM_LOAD16_BYTE  168xxx01.15h / 168xxx02.15f, 512 KB each, at 0x000000
    soundcpu   0x040000   168a05.7c (128 KB) and ROM_RELOAD
    k056832    0x600000   ROM_LOADTILE_WORD (GROUPWORD | SKIP(3) | REVERSE) x2 of 2 MB: 5-byte groups, the
                          fifth plane's byte is never loaded (ROMREGION_ERASE00): this game's tiles are 4bpp
    k055673    0x800000   ROM_LOAD64_WORD x4 (K055673_LAYOUT_RNG, 4bpp)
    k054539    0x400000   PCM, 2 x 2 MB

    python tools/vs_rom.py viostorm.zip [image.rom]    # verifies the image if given
    VSSET=viostormu python tools/vs_rom.py viostorm.zip
"""
import sys, zipfile, os, zlib, hashlib

# set -> (the two program-half files: odd byte 15h, even byte 15f)
SETS = {
    "viostorm":   ("168eac01.15h", "168eac02.15f"),
    "viostormeb": ("168eab01.15h", "168eab02.15f"),
    "viostormu":  ("168uac01.15h", "168uac02.15f"),
    "viostormub": ("168uab01.15h", "168uab02.15f"),
    "viostormj":  ("168jac01.b01", "168jac02.b02"),
    "viostorma":  ("168aac01.15h", "168aac02.15f"),
    "viostormab": ("168aab01.15h", "168aab02.15f"),
}
NVRAM = {k: k + ".nv" for k in SETS}      # the factory EEPROM, inside the merged zip
CRC = {
    "168a05.7c": 0x507fb3eb,
    "168a06.1c": 0x25404fd7, "168a07.1e": 0xfdbbf8cc,
    "168a09.1h": 0x1b34a881, "168a08.1k": 0xdb0ce743,
    "168a10.22k": 0xbd2bbdea, "168a11.19k": 0x7a57c9e7, "168a12.20k": 0xb6b1c4ef, "168a13.17k": 0xcdec3650,
    "168eac01.15h": 0x9f6b5c81, "168eac02.15f": 0x126ecf03,
    "168eab01.15h": 0x4eee6a8e, "168eab02.15f": 0x8dd8aa4c,
    "168uac01.15h": 0x49853530, "168uac02.15f": 0x055ca6fe,
    "168uab01.15h": 0x2d6a9fa3, "168uab02.15f": 0x0e75f7cc,
    "168jac01.b01": 0xf8be1225, "168jac02.b02": 0xf42fd1e5,
    "168aac01.15h": 0x3620635c, "168aac02.15f": 0xdb679aec,
    "168aab01.15h": 0x14f78423, "168aab02.15f": 0x3dd1cc83,
    "viostorm.nv": 0x3cb1c96c, "viostormeb.nv": 0x28b5fe49, "viostormu.nv": 0x797042a1, "viostormub.nv": 0xb6937413,
    "viostormj.nv": 0x32f5d8bc, "viostorma.nv": 0x2cfbf966, "viostormab.nv": 0x38ffce43,
}

# image layout: name -> (offset, size)
IMG = {
    "prog":  (0x0000000, 0x200000),   # 68000 program, the map's 2 MB (0x100000..0x1fffff zero)
    "snd":   (0x0200000, 0x040000),   # Z80 program
    "tile":  (0x0240000, 0x400000),   # K056832 tile ROM, 4 chunky bytes a row of 8 pixels
    "pcm":   (0x0640000, 0x400000),   # K054539 PCM, 2 x 2 MB
    "spr":   (0x0A40000, 0x800000),   # K055673 sprite ROM, a 64-bit word a 16-pixel row
}
IMG_END = 0x1240000


def load_files(path):
    out = {}
    if os.path.isdir(path):
        for root, _, files in os.walk(path):
            for f in files:
                with open(os.path.join(root, f), "rb") as fh:
                    d = fh.read()
                out.setdefault(f.lower(), []).append(d)
    else:
        with zipfile.ZipFile(path) as z:
            for i in z.infolist():
                if not i.is_dir():
                    out.setdefault(os.path.basename(i.filename).lower(), []).append(z.read(i))
    return out


def rom(files, name):
    want = CRC[name]
    for d in files.get(name.lower(), []):
        if zlib.crc32(d) & 0xffffffff == want:
            return d
    raise SystemExit("%s: missing or wrong crc" % name)


def regions(path, setname="viostorm"):
    files = load_files(path)
    p1, p0 = SETS[setname]               # 15h = odd bytes, 15f = even bytes
    r = {}
    # maincpu: ROM_LOAD16_BYTE(15h, 0x000001), (15f, 0x000000), 512 KB each
    m = bytearray(0x200000)
    for name, base in ((p0, 0), (p1, 1)):
        d = rom(files, name)
        m[base:base + 2 * len(d):2] = d
    r["maincpu"] = bytes(m)
    d = rom(files, "168a05.7c")
    r["soundcpu"] = d + d                # ROM_LOAD + ROM_RELOAD
    # k056832: 5-byte groups. ROM_LOADTILE_WORD: 16-bit groups, 3 bytes skipped, REVERSE swaps the pair
    t = bytearray(0x600000)
    for name, off in (("168a09.1h", 0), ("168a08.1k", 2)):
        d = rom(files, name)
        n = len(d) // 2
        t[off + 0: off + 5 * n: 5] = d[1::2]       # file byte 2n+1 first (reversed)
        t[off + 1: off + 1 + 5 * n: 5] = d[0::2]
    r["k056832"] = bytes(t)
    # k055673: ROM_LOAD64_WORD (8-byte stride, 16-bit groups, file order)
    s = bytearray(0x800000)
    for name, off in (("168a10.22k", 0), ("168a11.19k", 2), ("168a12.20k", 4), ("168a13.17k", 6)):
        d = rom(files, name)
        n = len(d) // 2
        s[off + 0: off + 8 * n: 8] = d[0::2]
        s[off + 1: off + 1 + 8 * n: 8] = d[1::2]
    r["k055673"] = bytes(s)
    r["k054539"] = rom(files, "168a06.1c") + rom(files, "168a07.1e")
    r["eeprom"] = rom(files, NVRAM[setname])
    return r


def image(reg):
    """The flat image the core loads, from MAME's regions."""
    img = bytearray(IMG_END)
    def put(name, data):
        off, size = IMG[name]
        assert len(data) <= size, name
        img[off:off + len(data)] = data
    put("prog", reg["maincpu"])
    put("snd", reg["soundcpu"])
    k = reg["k056832"]
    n = 0x100000                                  # 1M groups of 5 bytes, 4 of them loaded
    t = bytearray(n * 4)
    for i in range(4):
        t[i::4] = k[i:5 * n:5]
    assert not any(k[4:5 * n:5]), "the fifth plane is expected to be empty"
    put("tile", t)
    put("pcm", reg["k054539"])
    put("spr", reg["k055673"])
    return bytes(img)


def verify(reg, img):
    exp = image(reg)
    if len(img) != len(exp):
        print("image is %d bytes, expected %d" % (len(img), len(exp)))
        return False
    ok = True
    for name, (off, size) in IMG.items():
        a, b = img[off:off + size], exp[off:off + size]
        if a == b:
            print("  %-5s ok" % name)
        else:
            i = next(i for i in range(size) if a[i] != b[i])
            print("  %-5s MISMATCH at +0x%x (image %02x, MAME %02x)" % (name, i, a[i], b[i]))
            ok = False
    return ok


def main():
    if len(sys.argv) < 2:
        print(__doc__); return 2
    setname = os.environ.get("VSSET", "viostorm")
    reg = regions(sys.argv[1], setname)
    for k, v in reg.items():
        print("%-9s %8d bytes  md5 %s" % (k, len(v), hashlib.md5(v).hexdigest()))
    if len(sys.argv) > 2:
        with open(sys.argv[2], "rb") as f:
            ok = verify(reg, f.read())
        print("IMAGE MATCHES MAME'S REGIONS" if ok else "IMAGE DOES NOT MATCH")
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
