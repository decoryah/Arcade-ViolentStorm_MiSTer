// rtl/vs_dac.sv against its own table read independently: a pixel tick every 12 clocks, a new colour and brightness
// after each tick (as the mixer's output changes), and at every tick the stage's output must be the previous pixel's
// colour through the table (Board DAC) or unchanged (MAME). Every code of every brightness step in both modes, then
// random pixels with the mode switching now and then.
//   sim/dac/run.sh
`timescale 1ns/1ps
module tb_vs_dac;
    reg clk = 0;
    always #5 clk = ~clk;
    reg         cen_pix = 0, board_dac = 1;
    reg  [23:0] rgb_in = 0;
    reg   [7:0] bri_in = 8'hff;
    wire [23:0] rgb_out;
    vs_dac #(.HEXDIR("../../rtl/data")) dut (.clk(clk), .cen_pix(cen_pix), .board_dac(board_dac),
                                             .rgb_in(rgb_in), .bri_in(bri_in), .rgb_out(rgb_out));
    reg [7:0] tab [0:16383];
    initial $readmemh("../../rtl/data/k054573_dac.hex", tab);

    integer errors = 0, checks = 0, i, seed = 32'h5eed;
    reg [23:0] want;
    reg [23:0] prev_rgb;
    reg  [7:0] prev_bri;
    reg        prev_mode, have_prev = 0;

    function automatic [23:0] expect_of(input [23:0] c, input [7:0] b, input m);
        expect_of = m ? {tab[{b[7:2], c[23:16]}], tab[{b[7:2], c[15:8]}], tab[{b[7:2], c[7:0]}]} : c;
    endfunction

    // one pixel period: the tick, the inputs change, eleven more clocks; checked just before the next tick
    task automatic pixel(input [23:0] c, input [7:0] b, input m);
        begin
            @(negedge clk);
            if (have_prev) begin
                want = expect_of(prev_rgb, prev_bri, prev_mode);
                checks = checks + 1;
                if (rgb_out !== want) begin
                    errors = errors + 1;
                    if (errors < 10) $display("MISMATCH: rgb %06x bri %02x mode %0d -> %06x, want %06x", prev_rgb, prev_bri, prev_mode, rgb_out, want);
                end
            end
            cen_pix = 1; @(negedge clk); cen_pix = 0;
            prev_rgb = rgb_in; prev_bri = bri_in; prev_mode = board_dac; have_prev = 1;   // what the tick latched
            rgb_in = c; bri_in = b; board_dac = m;
            repeat (10) @(negedge clk);
        end
    endtask

    initial begin
        repeat (5) @(negedge clk);
        for (i = 0; i < 64 * 256; i = i + 1) pixel({i[7:0], ~i[7:0], i[7:0] ^ 8'h5a}, {i[13:8], 2'b11}, 1'b1);
        for (i = 0; i < 4096; i = i + 1) pixel($random(seed), $random(seed), 1'b0);
        for (i = 0; i < 100000; i = i + 1) pixel($random(seed), $random(seed), ($random(seed) & 15) != 0);
        pixel(0, 0, 0);
        $display("%s: %0d pixels checked, %0d wrong", errors ? "FAIL" : "PASS", checks, errors);
        $finish;
    end
endmodule
