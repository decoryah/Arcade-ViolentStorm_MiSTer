// The K055550's homing-vector command (rtl/k055550.sv) against MAME's code, for every input.
//   MAME (konamigx_m.cpp, case 0xc0):
//     dx = (short)reg[0xc]; dy = (short)reg[0xd];
//     if (dx) { if (dy) { angle = (atan((double)dy / dx) * 128.0) / pi;  if (dx < 0) angle += 128;
//                         i = (angle - 0x40) & 0xff; }
//               else i = (dx > 0) ? 0xc0 : 0x40; }
//     else if (dy > 0) i = 0; else if (dy < 0) i = 0x80; else i = rand() & 0xff;      // angle is an int
//   RTL: the bit search of rtl/k055550.sv (S_HM_*), over the table rtl/data/tan128.hex.
//   g++ -O2 -fopenmp -o k550_ref sim/k550_ref.cpp && ./k550_ref rtl/data/tan128.hex
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cstdint>
static const double kPi = 3.14159265358979323846;   // kPi as a double

static uint64_t T[64];

static int rtl_angle(int dx, int dy) {         // dx, dy non zero; returns i
    uint64_t a = (uint64_t)abs(dy), b = (uint64_t)abs(dx);
    int q = 0;
    for (int j = 5; j >= 0; j--) {
        int cand = q | (1 << j);
        unsigned __int128 lhs = (unsigned __int128)a << 40;
        unsigned __int128 rhs = (unsigned __int128)b * T[cand];
        if (lhs >= rhs) q = cand;
    }
    int neg = (dx < 0) ^ (dy < 0);
    int angle = neg ? -q : q;
    if (dx < 0) angle += 128;
    return (angle - 0x40) & 0xff;
}

static int mame_angle(int dx, int dy) {
    int angle = (int)((atan((double)dy / dx) * 128.0) / kPi);
    if (dx < 0) angle += 128;
    return (angle - 0x40) & 0xff;
}

int main(int argc, char **argv) {
    FILE *f = fopen(argc > 1 ? argv[1] : "rtl/data/tan128.hex", "r");
    if (!f) { perror("tan128.hex"); return 2; }
    for (int i = 0; i < 64; i++) {
        unsigned long long v; if (fscanf(f, "%llx", &v) != 1) return 2; T[i] = v;
    }
    fclose(f);
    long long bad = 0, total = 0;
    const int step = argc > 2 ? atoi(argv[2]) : 1;     // a sampling step for a quick run
    #pragma omp parallel for reduction(+:bad,total) schedule(dynamic, 64)
    for (int dx = -32768; dx <= 32767; dx += step) {
        for (int dy = -32768; dy <= 32767; dy += step) {
            if (dx == 0 || dy == 0) continue;           // explicit cases in the RTL (and in MAME's code)
            int m = mame_angle(dx, dy), r = rtl_angle(dx, dy);
            total++;
            if (m != r) {
                bad++;
                #pragma omp critical
                if (bad < 20) printf("MISMATCH dx=%d dy=%d MAME %02x RTL %02x\n", dx, dy, m, r);
            }
        }
    }
    printf("%lld inputs, %lld mismatches\n", total, bad);
    return bad ? 1 : 0;
}
