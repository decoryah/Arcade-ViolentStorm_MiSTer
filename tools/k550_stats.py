import sys, re, collections
fn = sys.argv[1]
cmds = collections.defaultdict(list)
for line in open(fn):
    m = re.match(r'f(\d+) pc ([0-9a-f]+) CMD ([0-9a-f]+) mask \w+ data \w+ \| (.*)', line)
    if not m: continue
    f, pc, cmd, regs = int(m.group(1)), int(m.group(2), 16), m.group(3), [int(x, 16) for x in m.group(4).split()]
    cmds[cmd].append((f, pc, regs))

def show(title, items):
    print(title)
    for k, n in collections.Counter(items).most_common(14):
        print("   %6d  %s" % (n, k))

for cmd, lst in sorted(cmds.items()):
    print("=== CMD %s: %d writes, %d frames, pcs %s" % (cmd, len(lst), len(set(f for f, _, _ in lst)),
          sorted(set("%06x" % pc for _, pc, _ in lst))))
    if cmd in ('9f', '97'):
        show("  (adr, bytes/unit, units, fill)", [("%06x" % ((r[7] << 16) | r[8]), (r[10] << 16) | r[11], (r[0] & 0xff) + 1, "%04x" % r[13]) for _, _, r in lst])
    elif cmd == 'a0':
        show("  (count, skipbytes, bsize, adr)", [(r[0] & 0xff, r[1] >> 7, (r[5] << 16) | r[6], "%06x" % ((r[2] << 16) | r[3])) for _, _, r in lst])
        per_frame = collections.Counter(f for f, _, _ in lst)
        print("   a0 per frame:", collections.Counter(per_frame.values()))
    elif cmd == 'c0':
        show("  (dx, dy signed)", [(((r[12] ^ 0x8000) - 0x8000), ((r[13] ^ 0x8000) - 0x8000)) for _, _, r in lst][:0])
        print("   first 8:", [((r[12] ^ 0x8000) - 0x8000, (r[13] ^ 0x8000) - 0x8000) for _, _, r in lst[:8]])
    elif cmd == '98':
        show("  (dst, src, count)", [("%06x" % ((r[7] << 16) | r[8]), "%06x" % ((r[2] << 16) | r[3]), ((r[10] << 16) | r[11]) >> 2) for _, _, r in lst])
    elif cmd == '87':
        show("  (count, i, adr, lim, src, tgt)", [((r[0] & 0xff) + 1, r[1], "%06x" % ((r[7] << 16) | r[8]), r[9], "%06x" % ((r[10] << 16) | r[11]), "%06x" % ((r[12] << 16) | r[13])) for _, _, r in lst])
