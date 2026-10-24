// Full-frame bench: every video block plus the mixer, one whole frame from a
// frozen state, out as RGB for comparison against MAME's snapshot of the same frame.
//
//   tb_frame <state.txt> <image.rom> <zoom.hex> <recip.hex> <out.rgb>
// BRI_POST=1: the mixer's Board DAC mode (colours mixed unscaled); BRI_OUT=<file>: the per-pixel brightness the mixer
// passes on, one byte a pixel
// The image is the flat ROM image the core loads (tools/mra_build.py on mra/*.mra).
#include "Vtb_frame_top.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <map>

static const int VIS_W = 384, VIS_H = 224, VIS_Y0 = 16, HTOTAL = 512, PIXCLK = 12, VIS_X0 = 40;
// the tile ROM is 4 MB; the renderer's 16-bit tile codes address its first 2 MB (the bench's tile memory)
static const long IMG_TILE = 0x240000, TILE_LEN = 0x200000;
static const long IMG_SPR  = 0xA40000, SPR_LEN  = 0x800000;

static Vtb_frame_top *dut;
static void tick() { dut->clk = 0; dut->eval(); dut->clk = 1; dut->eval(); }

struct State {
    std::map<std::string, std::vector<unsigned>> f;
    std::vector<std::vector<unsigned>> vram;
};

static State load_state(const char *path) {
    State st; st.vram.resize(17);
    FILE *fp = fopen(path, "r");
    if (!fp) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
    char *line = nullptr; size_t cap = 0;
    while (getline(&line, &cap, fp) > 0) {
        if (line[0] == '#') continue;
        char *save = nullptr;
        char *key = strtok_r(line, " \t\n", &save);
        if (!key) continue;
        int page = -1;
        if (!strcmp(key, "VRAM")) page = atoi(strtok_r(nullptr, " \t\n", &save));
        std::vector<unsigned> v; char *t;
        while ((t = strtok_r(nullptr, " \t\n", &save))) v.push_back((unsigned)strtoul(t, nullptr, 16));
        if (page >= 0) st.vram[page] = v; else st.f[key] = v;
    }
    free(line); fclose(fp);
    return st;
}

static std::vector<unsigned> load_hex(const char *path) {
    std::vector<unsigned> v; char buf[64];
    FILE *fp = fopen(path, "r");
    if (!fp) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
    while (fgets(buf, sizeof buf, fp)) v.push_back((unsigned)strtoul(buf, nullptr, 16));
    fclose(fp); return v;
}

static std::vector<unsigned char> load_region(FILE *rf, long off, long len, const char *what) {
    std::vector<unsigned char> d(len);
    fseek(rf, off, SEEK_SET);
    if (fread(d.data(), 1, len, rf) != (size_t)len) { fprintf(stderr, "short read of %s\n", what); exit(1); }
    return d;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 6) { fprintf(stderr, "usage: %s <state.txt> <image> <zoom.hex> <recip.hex> <out.rgb>\n", argv[0]); return 2; }
    State st = load_state(argv[1]);
    FILE *rf = fopen(argv[2], "rb");
    if (!rf) { fprintf(stderr, "cannot open %s\n", argv[2]); return 1; }
    auto tiles = load_region(rf, IMG_TILE, TILE_LEN, "tiles");
    auto spr   = load_region(rf, IMG_SPR, SPR_LEN, "sprites");
    fclose(rf);
    auto zoomtab = load_hex(argv[3]), reciptab = load_hex(argv[4]);

    dut = new Vtb_frame_top;
    dut->reset = 1; for (int i = 0; i < 8; i++) tick();
    dut->reset = 0;
    for (int i = 0; i < 64; i++) tick();

    auto &k56 = st.f["K56REGS"]; auto &k55 = st.f["K55REGS"]; auto &k38 = st.f["K38REGS"];
    auto &k46 = st.f["K46REGS"]; auto &k47 = st.f["K47REGS"];
    for (int i = 0; i < 32; i++) { dut->k56_we = 1; dut->k56_addr = i; dut->k56_data = k56[i]; tick(); }
    dut->k56_we = 0;
    // FORCE_ENABLE=<hex>: the K055555 layer enables, as the Lua probe's FORCE_ENABLE rewrote them for MAME
    if (getenv("FORCE_ENABLE")) k55[45] = (unsigned)strtoul(getenv("FORCE_ENABLE"), nullptr, 16);
    for (int i = 0; i < 48; i++) { dut->k55_we = 1; dut->k55_addr = i; dut->k55_data = k55[i] & 0xff; tick(); }
    dut->k55_we = 0;
    for (int i = 0; i < 16; i++) { dut->k38_we = 1; dut->k38_addr = i; dut->k38_data = k38[i]; tick(); }
    dut->k38_we = 0;
    dut->cfg_we = 1;
    dut->opset_i = k47[6];
    dut->k46r5_i = k46[5] & 0xff;
    dut->k46offx_i = ((k46[0] & 0xff) << 8) | (k46[1] & 0xff);
    dut->k46offy_i = ((k46[2] & 0xff) << 8) | (k46[3] & 0xff);
    tick(); dut->cfg_we = 0;

    for (int page = 0; page < 16; page++)
        for (size_t i = 0; i < st.vram[page].size(); i++) {
            dut->vram_we = 1; dut->vram_waddr = (page << 12) | i; dut->vram_wdata = st.vram[page][i]; tick();
        }
    dut->vram_we = 0;
    auto &pal = st.f["PALETTE"];
    for (int i = 0; i < 2048; i++) {
        dut->pal_we = 1; dut->pal_waddr = i;
        dut->pal_wdata = ((pal[i*2] & 0xff) << 16) | pal[i*2+1]; tick();
    }
    dut->pal_we = 0;
    auto &sr = st.f["SPRITERAM"];
    for (size_t i = 0; i < sr.size() && i < 2048; i++) { dut->sram_we = 1; dut->sram_waddr = i; dut->sram_wdata = sr[i]; tick(); }
    dut->sram_we = 0;
    // tile ROM: 4 chunky bytes a row of 8 pixels, the fifth plane's byte is 0
    for (long g = 0; g < TILE_LEN / 4; g++) {
        unsigned long long v = 0;
        for (int b = 0; b < 4; b++) v = (v << 8) | tiles[g*4+b];
        v <<= 8;
        dut->trom_we = 1; dut->trom_waddr = g; dut->trom_wdata = v; tick();
    }
    dut->trom_we = 0;
    for (long u = 0; u < SPR_LEN / 8; u++) {
        unsigned long long hi = 0;
        for (int b = 0; b < 8; b++) hi = (hi << 8) | spr[u*8+b];
        // {row64, 16 zero bits} as an 80-bit word: [79:16] row
        dut->srom_wdata[0] = (unsigned)((hi << 16) & 0xffffffffu);
        dut->srom_wdata[1] = (unsigned)(hi >> 16);
        dut->srom_wdata[2] = (unsigned)(hi >> 48);
        dut->srom_we = 1; dut->srom_waddr = u; tick();
    }
    dut->srom_we = 0;
    for (size_t i = 0; i < zoomtab.size(); i++) { dut->tab_we = 1; dut->tab_sel = 0; dut->tab_waddr = i; dut->tab_wdata = zoomtab[i]; tick(); }
    for (size_t i = 0; i < reciptab.size(); i++) { dut->tab_we = 1; dut->tab_sel = 1; dut->tab_waddr = i; dut->tab_wdata = reciptab[i]; tick(); }
    dut->tab_we = 0;

    // build the object list, as the update pass would
    dut->build = 1; tick(); dut->build = 0;
    long c = 0;
    while (!dut->build_done) { tick(); if (++c > 2000000) { fprintf(stderr, "objlist hung\n"); return 1; } }
    printf("object list built in %ld clocks%c", c, 10);

    std::vector<unsigned> out(VIS_H * VIS_W, 0);
    std::vector<unsigned char> outb(VIS_H * VIS_W, 0);
    dut->bri_post = getenv("BRI_POST") ? 1 : 0;
    long worst = 0, worst_tm = 0, worst_dr = 0;
    long hist[64] = {0}, worst_hist[64] = {0}; int worst_hist_line = -1;
    // TCACHE=1: replay the tile ROM requests through direct-mapped row caches of several sizes (a study)
    const bool tcache = getenv("TCACHE") != nullptr;
    const int NC = 5; const int csz[NC] = {64, 256, 512, 1024, 2048};
    std::vector<std::vector<long>> ctag(NC);
    for (int c = 0; c < NC; c++) ctag[c].assign(csz[c], -1);
    long creq = 0, chit[NC] = {0}; bool prev_ack = false;
    auto render_line = [&](int raster_y) -> long {
        dut->line_start = 1; dut->line = raster_y; tick(); dut->line_start = 0;
        long n = 0;
        long n_tm = 0, n_dr = 0;
        memset(hist, 0, sizeof hist);
        while (dut->busy) {
            tick(); if (++n > 2000000) { fprintf(stderr, "line %d hung\n", raster_y); exit(1); }
            if (tcache && dut->dbg_trom_ack && !prev_ack) {
                long ad = dut->dbg_trom_addr; creq++;
                for (int c = 0; c < NC; c++) {
                    int ix = (int)((ad ^ (ad >> 9) ^ (ad >> 18)) & (csz[c] - 1));
                    if (ctag[c][ix] == ad) chit[c]++; else ctag[c][ix] = ad;
                }
            }
            prev_ack = dut->dbg_trom_ack;
            if (dut->busy_src & 4) n_tm = n; if (dut->busy_src & 1) { n_dr = n; hist[dut->dbg_dr_st & 63]++; }
        }
        if (n_tm > worst_tm) worst_tm = n_tm;
        if (n_dr > worst_dr) { worst_dr = n_dr; memcpy(worst_hist, hist, sizeof hist); worst_hist_line = raster_y; }
        return n;
    };
    // the sprite drawer starts on the new list and runs through the vblank as far as its ring allows
    // (SPR_LEAD lines before the picture)
    const int SPR_LEAD = 3;
    dut->hcount_i = 0;
    auto prologue = [&]() {
        dut->vcount = VIS_Y0 - 1;
        for (int k = 0; k < 5 * HTOTAL * PIXCLK; k++) tick();     // five raster lines before the first pulse
        long w = 0;
        while (dut->spr_done_line < VIS_Y0 + SPR_LEAD - 1 && w < 4000000) { tick(); w++; }
        render_line(VIS_Y0);
    };
    prologue();
    dut->px_valid = 1;
    // REALTIME=1: the renderers get what the raster gives them -- one line period, 6144 clocks, from each pulse, while
    // the line before is scanned out -- and are restarted by the next pulse if still busy, as in vs_video; the memories'
    // latencies (+LAT_*) then decide which lines come out short. Default: each line is rendered to completion.
    const bool realtime = getenv("REALTIME") != nullptr;
    const int dbgrow = getenv("DBGROW") ? atoi(getenv("DBGROW")) : -1;
    int overrun_lines = 0;
    std::vector<int> overrun_rows;
    for (int y = 0; y < VIS_H && realtime; y++) {
        dut->vcount = VIS_Y0 + y; dut->hcount_i = VIS_X0;
        dut->line_start = 1; dut->line = VIS_Y0 + y + 1; tick(); dut->line_start = 0;
        long n = 1;
        for (int x = 0; x < VIS_W; x++) {
            dut->px = x; dut->cen_pix = 1; tick(); dut->cen_pix = 0; n++;
            for (int k = 0; k < PIXCLK - 1; k++) { tick(); n++; }
            if (x > 0) out[y * VIS_W + x - 1] = dut->rgb;
        }
        dut->px = VIS_W - 1; dut->cen_pix = 1; tick(); dut->cen_pix = 0; n++;
        for (int k = 0; k < PIXCLK - 1; k++) { tick(); n++; }
        out[y * VIS_W + VIS_W - 1] = dut->rgb;
        for (; n < (long)HTOTAL * PIXCLK; n++) tick();
        dut->vcount = VIS_Y0 + y + 1; dut->eval();
        if (dut->busy) { overrun_lines++; overrun_rows.push_back(y); }
    }
    if (realtime) {
        printf("REALTIME: %d of %d lines were still being rendered when the next pulse came", overrun_lines, VIS_H);
        if (!overrun_rows.empty()) {         // as ranges
            printf(" (rows");
            for (size_t i = 0; i < overrun_rows.size();) {
                size_t j = i; while (j + 1 < overrun_rows.size() && overrun_rows[j + 1] == overrun_rows[j] + 1) j++;
                if (j > i) printf(" %d-%d", overrun_rows[i], overrun_rows[j]); else printf(" %d", overrun_rows[i]);
                i = j + 1;
            }
            printf(")");
        }
        printf("\n");
    }
    printf("sprite row cache: %u hits, %u misses\n", (unsigned)dut->cache_hits, (unsigned)dut->cache_misses);
    dut->hcount_i = 0;
    for (int y = 0; y < VIS_H && !realtime; y++) {
        dut->vcount = VIS_Y0 + y;
        long n = render_line(VIS_Y0 + y + 1);
        if (n > worst) worst = n;
        for (int x = 0; x < VIS_W; x++) {
            // a 16-clock pixel as vs_video paces it: px changes on the tick,
            // the mixer latches and sequences at fixed phases after it
            dut->px = x; dut->cen_pix = 1; tick(); dut->cen_pix = 0;
            for (int k = 0; k < PIXCLK - 1; k++) tick();
            if (x > 0) { out[y * VIS_W + x - 1] = dut->rgb; outb[y * VIS_W + x - 1] = dut->bri; }   // a pixel period late
            if (dbgrow == y && x < 160 && (dut->dbg_opq || dut->rgb)) printf("  x%3d opq %x pen %03x %03x %03x %03x rgb(x-1) %06x\n", x, dut->dbg_opq, dut->dbg_pen0, dut->dbg_pen1, dut->dbg_pen2, dut->dbg_pen3, dut->rgb);
        }
        dut->px = VIS_W - 1; dut->cen_pix = 1; tick(); dut->cen_pix = 0;     // one more period: the last pixel's colour
        for (int k = 0; k < PIXCLK - 1; k++) tick();
        out[y * VIS_W + VIS_W - 1] = dut->rgb; outb[y * VIS_W + VIS_W - 1] = dut->bri;
        for (int k = 0; k < (HTOTAL - VIS_W - 1) * PIXCLK; k++) tick();    // the line's blanking: 6144 clocks a line in all
    }
    if (dut->unsupported) { fprintf(stderr, "RTL raised `unsupported` (or the object list overflowed)\n"); return 1; }
    if (dut->shadow_overlap) fprintf(stderr, "warning: a pixel was shadowed twice\n");

    FILE *of = fopen(argv[5], "wb");
    if (!of) { fprintf(stderr, "cannot write %s\n", argv[5]); return 1; }
    fwrite(out.data(), 4, out.size(), of); fclose(of);
    if (getenv("BRI_OUT")) { FILE *bf = fopen(getenv("BRI_OUT"), "wb"); if (bf) { fwrite(outb.data(), 1, outb.size(), bf); fclose(bf); } }
    if (getenv("HIST")) {
        printf("sprite drawer, worst line (raster %d), clocks per state:", worst_hist_line);
        for (int s = 0; s < 64; s++) if (worst_hist[s]) printf(" %d:%ld", s, worst_hist[s]);
        printf("%c", 10);
    }
    printf("worst line %ld clocks (budget 6144; tilemap %ld, sprites %ld)\n", worst, worst_tm, worst_dr);
    if (tcache) {
        printf("tile ROM requests %ld; direct-mapped row cache hits:", creq);
        for (int c = 0; c < NC; c++) printf(" %d:%.1f%%", csz[c], creq ? 100.0 * chit[c] / creq : 0.0);
        printf("\n");
    }
    delete dut;
    return 0;
}
