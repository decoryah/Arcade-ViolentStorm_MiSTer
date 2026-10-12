// Furrtek's silicon-derived K053252 model (ref/siliconre/053252_hdl_053252.v), programmed with a game's registers,
// reports where the chip puts hblank / hsync / vblank / vsync, in pixel clocks and lines.
//   iverilog -g2012 -DREGS=128'h01FF0016003900000107110E75000000 -o tb tb_k252.v ../../../ref/siliconre/053252_hdl_053252.v
//   (74163.v from the same directory is included by the model; the CLK is 4 x the pixel clock, SEL = 0)
// Output: one line per edge, "t=<pixel clock count of CLK2> <signal> <level>" for a few frames, then a summary.
`timescale 1ns/1ps

module tb_k252;
`ifndef REGS
`define REGS 128'h01FF0016003900000107110E75000000
`endif
    reg clk = 0;
    reg rst_n = 0;
    reg ccs = 1, rw = 1;
    reg [3:0] ab = 0;
    reg [7:0] db = 0;

    wire nhbk, nhsy, nvbk, nvsy, nhbs, ncbk, ncsy, clk1, clk2, clk3, clk4, pe, pq, cres, nhld, nvld, fcnt, int1, int2;
    wire [7:0] db_out;

    k053252 u (
        .PIN_RESET(rst_n), .PIN_CLK(clk), .PIN_SEL(3'd0), .PIN_CCS(ccs), .PIN_RW(rw), .PIN_AB(ab),
        .PIN_DB_IN(db), .PIN_HLD1(1'b1), .PIN_VLD1(1'b1), .PIN_DB_OUT(db_out),
        .PIN_CLK1(clk1), .PIN_CLK2(clk2), .PIN_CLK3(clk3), .PIN_CLK4(clk4), .PIN_PE(pe), .PIN_PQ(pq), .PIN_CRES(cres),
        .PIN_NHLD(nhld), .PIN_NHSY(nhsy), .PIN_NVSY(nvsy), .PIN_NVLD(nvld), .PIN_FCNT(fcnt),
        .PIN_INT1(int1), .PIN_INT2(int2), .PIN_NCBK(ncbk), .PIN_NCSY(ncsy), .PIN_NVBK(nvbk), .PIN_NHBS(nhbs), .PIN_NHBK(nhbk)
    );

    always #15.625 clk = ~clk;      // 32 MHz

    integer k;
    task wr(input [3:0] a, input [7:0] d);
        begin
            @(negedge clk); ab = a; db = d; rw = 0; ccs = 0;
            repeat (4) @(negedge clk);
            rw = 1; ccs = 1;
            repeat (4) @(negedge clk);
        end
    endtask

    reg [127:0] cfg = `REGS;
    initial begin
        #100 rst_n = 1;
        repeat (50) @(negedge clk);
        for (k = 0; k < 16; k = k + 1) wr(k[3:0], cfg[(15 - k) * 8 +: 8]);
    end

    // time in pixel clocks (CLK2 rising edges), lines counted on the falling edge of nhbk's rising (hblank end)
    integer pix = 0;
    reg started = 0;
    always @(posedge clk2) if (rst_n) pix <= pix + 1;

    reg l_nhbk = 1, l_nhsy = 1, l_nvbk = 1, l_nvsy = 1;
    integer n_edges = 0;
    always @(posedge clk) begin
        if (nhbk !== l_nhbk) begin $display("t=%0d NHBK %0d", pix, nhbk); l_nhbk <= nhbk; end
        if (nhsy !== l_nhsy) begin $display("t=%0d NHSY %0d", pix, nhsy); l_nhsy <= nhsy; end
        if (nvbk !== l_nvbk) begin $display("t=%0d NVBK %0d", pix, nvbk); l_nvbk <= nvbk; end
        if (nvsy !== l_nvsy) begin $display("t=%0d NVSY %0d", pix, nvsy); l_nvsy <= nvsy; end
    end

    initial begin
        #90000000;     // 90 ms: about five frames
        $finish;
    end
endmodule
