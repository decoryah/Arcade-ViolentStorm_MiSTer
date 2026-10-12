// K055550 unit bench against a transcription of MAME's K055550_word_w (konamigx_m.cpp): random programs of
// every command on a random memory, the 68000's register writes as the board makes them (a command is a write
// to the high byte of register 0).
//
//   tb_k550 [seed] [iterations]
//
// A 16 MB byte-addressed memory is modelled; the RTL's bus is the word array of tb_k550_top.
#include "Vtb_k550_top.h"
#include "Vtb_k550_top___024root.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <cmath>
#include <vector>

static Vtb_k550_top *dut;
static inline void tick() { dut->clk = 0; dut->eval(); dut->clk = 1; dut->eval(); }
static const double kPi = 3.14159265358979323846;

static const int MEMW = 1 << 23;                 // words
static std::vector<uint16_t> ref_mem(MEMW);
static uint16_t prot[32];

static uint8_t rd8(uint32_t a)  { a &= 0xffffff; uint16_t w = ref_mem[a >> 1]; return (a & 1) ? (w & 0xff) : (w >> 8); }
static void wr8(uint32_t a, uint8_t v) {
    a &= 0xffffff; uint16_t &w = ref_mem[a >> 1];
    if (a & 1) w = (w & 0xff00) | v; else w = (w & 0x00ff) | ((uint16_t)v << 8);
}
static uint16_t rd16(uint32_t a) { a &= 0xffffff; return ref_mem[a >> 1]; }                 // aligned only
static void wr16(uint32_t a, uint16_t v) { a &= 0xffffff; ref_mem[a >> 1] = v; }
static uint32_t rd32(uint32_t a) { return ((uint32_t)rd16(a) << 16) | rd16(a + 2); }
static void wr32(uint32_t a, uint32_t v) { wr16(a, v >> 16); wr16(a + 2, v & 0xffff); }

// MAME's command switch, the memset, copy, collision list and homing vector
static void mame_cmd(int cmd) {
    uint32_t adr, bsize, count, i, lim, src, dst;
    int tgt, srcend, tgtend, skip, cx1, sx1, wx1, cy1, sy1, wy1, cz1, sz1, wz1, c2, s2, w2, dx, dy, angle;
    switch (cmd) {
    case 0x97: case 0x9f:
        adr = ((uint32_t)prot[7] << 16) | prot[8]; bsize = ((uint32_t)prot[10] << 16) | prot[11]; count = (prot[0] & 0xff) + 1;
        lim = adr + bsize * count;
        for (i = adr; i < lim; i += 2) wr16(i, prot[0x1a / 2]);
        break;
    case 0x98:
        dst = ((uint32_t)prot[7] << 16) | prot[8]; src = ((uint32_t)prot[2] << 16) | prot[3];
        count = (((uint32_t)prot[10] << 16) | prot[11]) >> 2;
        for (uint32_t x = 0; x < count; ++x) wr32(dst + x * 4, rd32(src + x * 8));
        break;
    case 0xa0:
        count = prot[0] & 0xff; skip = prot[1] >> (8 - 1);
        adr = ((uint32_t)prot[2] << 16) | prot[3]; bsize = ((uint32_t)prot[5] << 16) | prot[6];
        srcend = adr + bsize * count; tgtend = srcend + bsize;
        for (src = adr; src < (uint32_t)srcend; src += bsize) {
            cx1 = (short)rd16(src);      sx1 = (short)rd16(src + 2);  wx1 = (short)rd16(src + 4);
            cy1 = (short)rd16(src + 6);  sy1 = (short)rd16(src + 8);  wy1 = (short)rd16(src + 10);
            cz1 = (short)rd16(src + 12); sz1 = (short)rd16(src + 14); wz1 = (short)rd16(src + 16);
            count = i = src + skip; tgt = src + bsize;
            for (; count < (uint32_t)tgt; count++) wr8(count, 0);
            for (; tgt < tgtend; i++, tgt += bsize) {
                c2 = (short)rd16(tgt); s2 = (short)rd16(tgt + 2); w2 = (short)rd16(tgt + 4);
                if (abs((cx1 + sx1) - (c2 + s2)) >= wx1 + w2) continue;
                c2 = (short)rd16(tgt + 6); s2 = (short)rd16(tgt + 8); w2 = (short)rd16(tgt + 10);
                if (abs((cy1 + sy1) - (c2 + s2)) >= wy1 + w2) continue;
                c2 = (short)rd16(tgt + 12); s2 = (short)rd16(tgt + 14); w2 = (short)rd16(tgt + 16);
                if (abs((cz1 + sz1) - (c2 + s2)) >= wz1 + w2) continue;
                wr8(i, 0x80);
            }
        }
        break;
    case 0xc0:
        dx = (short)prot[0xc]; dy = (short)prot[0xd];
        if (dx) {
            if (dy) {
                angle = (int)((atan((double)dy / dx) * 128.0) / kPi);
                if (dx < 0) angle += 128;
                i = (angle - 0x40) & 0xff;
            } else i = (dx > 0) ? 0xc0 : 0x40;
        } else if (dy > 0) i = 0;
        else if (dy < 0) i = 0x80;
        else i = 0x1234;                        // random in MAME: not compared
        prot[0x10] = i;
        break;
    default: break;
    }
}

static void write_reg(int idx, uint16_t v, int be = 3) {
    dut->wr = 1; dut->idx = idx; dut->be = be; dut->wdata = v; tick();
    dut->wr = 0; tick();
    if (idx < 32) {
        if (be & 2) prot[idx] = (prot[idx] & 0x00ff) | (v & 0xff00);
        if (be & 1) prot[idx] = (prot[idx] & 0xff00) | (v & 0x00ff);
    }
}
static void run_cmd(int cmd) {
    // a command is a write to the high byte of register 0 (UDS only): the register's low byte stays
    dut->wr = 1; dut->idx = 0; dut->be = 2; dut->wdata = (cmd << 8) | 0x00; tick();
    dut->wr = 0; tick();
    prot[0] = (prot[0] & 0x00ff) | (cmd << 8);
    long n = 0;
    while (dut->busy && ++n < 50000000) tick();
    if (n >= 50000000) { fprintf(stderr, "command %02x hung\n", cmd); exit(1); }
    mame_cmd(cmd);
}

static uint32_t rng = 1;
static uint32_t rnd() { rng = rng * 1664525u + 1013904223u; return rng >> 8; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc > 1) rng = (uint32_t)strtoul(argv[1], nullptr, 0);
    int iters = argc > 2 ? atoi(argv[2]) : 60;
    dut = new Vtb_k550_top;
    dut->reset = 1; for (int i = 0; i < 8; i++) tick();
    dut->reset = 0; for (int i = 0; i < 8; i++) tick();
    auto &m = dut->rootp->tb_k550_top__DOT__mem;
    // a random memory in the regions the commands use (everything below 0x10000 words and the 0x20xxxx block)
    for (int i = 0; i < MEMW; i++) { uint16_t v = (uint16_t)rnd(); ref_mem[i] = v; m[i] = v; }
    long bad = 0, cmds = 0;
    for (int it = 0; it < iters; it++) {
        int kind = rnd() % 5;
        int cmd = kind == 0 ? 0x9f : kind == 1 ? 0x97 : kind == 2 ? 0xa0 : kind == 3 ? 0xc0 : 0x98;
        // registers of a plausible program, addresses in a 1 MB window of the memory
        uint32_t base = (rnd() & 0xfffff) & ~1u;
        auto setreg32 = [&](int hi, uint32_t v) { write_reg(hi, v >> 16); write_reg(hi + 1, v & 0xffff); };
        if (cmd == 0x9f || cmd == 0x97) {
            uint32_t bs = (rnd() % 8) * 2 + 2, cnt = rnd() % 12;             // bytes a unit (even), units - 1
            setreg32(7, base); setreg32(10, bs); write_reg(13, (uint16_t)rnd());
            write_reg(0, 0x0000 | cnt, 1);                                    // the count in the low byte
        } else if (cmd == 0x98) {
            uint32_t src = ((rnd() & 0x7ffff) & ~7u) + 0x100000, n = (rnd() % 16) + 1;
            setreg32(2, src); setreg32(7, base); setreg32(10, n * 4);
        } else if (cmd == 0xa0) {
            uint32_t bs = 0x20 + (rnd() % 8) * 0x10, sk = 18 + (rnd() % 4) * 2;     // bytes an object, the hit list's offset
            uint32_t nobj = (rnd() % 6) + 1;                                   // objects - 1 is `count`
            setreg32(2, base); setreg32(5, bs); write_reg(1, (uint16_t)(sk << 7)); write_reg(0, (uint16_t)(nobj), 1);
            // objects near each other so that some pairs overlap on all three axes
            for (uint32_t o = 0; o <= nobj; o++) {
                for (int a = 0; a < 3; a++) {
                    int c = (int)(rnd() % 120) - 60, s = (int)(rnd() % 20) - 10, w = (int)(rnd() % 50);
                    uint32_t pa = base + o * bs + a * 6;
                    wr16(pa, (uint16_t)c); wr16(pa + 2, (uint16_t)s); wr16(pa + 4, (uint16_t)w);
                    m[(pa & 0xffffff) >> 1] = (uint16_t)c; m[((pa + 2) & 0xffffff) >> 1] = (uint16_t)s; m[((pa + 4) & 0xffffff) >> 1] = (uint16_t)w;
                }
            }
        } else {                                                              // 0xc0: dx, dy
            int dx, dy;
            switch (rnd() % 6) {
                case 0: dx = 0; dy = (int)(rnd() % 400) - 200; if (!dy) dy = 1; break;
                case 1: dy = 0; dx = (int)(rnd() % 400) - 200; if (!dx) dx = 1; break;
                default: dx = (int)(rnd() % 65536) - 32768; dy = (int)(rnd() % 65536) - 32768; break;
            }
            write_reg(12, (uint16_t)dx); write_reg(13, (uint16_t)dy);
        }
        run_cmd(cmd);
        cmds++;
        // compare: the memory (every word that either side wrote is checked by the whole-array scan below) and the registers
        if (cmd == 0xc0) {
            dut->rd_idx = 16; tick(); tick();
            if (dut->rd_q != prot[0x10]) { if (bad < 8) printf("HOMING dx=%d dy=%d: RTL %04x MAME %04x\n", (short)prot[12], (short)prot[13], dut->rd_q, prot[0x10]); bad++; }
        }
    }
    // the whole memory
    long mem_bad = 0;
    for (int i = 0; i < MEMW; i++)
        if (m[i] != ref_mem[i]) { if (mem_bad < 8) printf("MEM word %06x: RTL %04x MAME %04x\n", i * 2, (unsigned)m[i], ref_mem[i]); mem_bad++; }
    for (int r = 0; r < 32; r++) {
        dut->rd_idx = r; tick(); tick();
        if (r != 16 && dut->rd_q != prot[r]) { printf("REG %d: RTL %04x MAME %04x\n", r, dut->rd_q, prot[r]); bad++; }
    }
    printf("%ld commands, %u bus accesses; %ld result mismatches, %ld memory words differ\n", cmds, (unsigned)dut->n_access, bad, mem_bad);
    delete dut;
    return (bad || mem_bad) ? 1 : 0;
}
