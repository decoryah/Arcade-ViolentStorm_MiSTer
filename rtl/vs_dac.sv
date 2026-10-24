//------------------------------------------------------------------------------
// The board's video DACs (the OSD's Colours = Board DAC): a Konami 054573 per channel turns the 8-bit colour into a
// voltage, and the K054338's brightness output sets the current they run on through a 054574. The output is not
// linear in the code (mid tones darker than MAME's palette), and the brightness dims it after the curve. One table,
// tools/make_dac_table.py -> rtl/data/k054573_dac.hex: 64 brightness steps x 256 codes (address = bri[7:2] * 256 +
// code), the model of the traced circuit fitted to a recording of a Violent Storm PCB (docs/hardware.md "Colours").
//
// A pixel's colour and brightness are latched at the pixel tick; the three channels are looked up one after another
// in the next clocks and the result is out five clocks after the tick, so a pixel leaves this stage one pixel period
// after it came in (vs_core delays de and the syncs one more pixel to match). With board_dac = 0 (Colours = MAME) the
// colour passes through unchanged, with the same delay.
//------------------------------------------------------------------------------
`default_nettype none

module vs_dac #(
    parameter string HEXDIR = "rtl/data"
) (
    input  logic        clk,
    input  logic        cen_pix,
    input  logic        board_dac,
    input  logic [23:0] rgb_in,
    input  logic  [7:0] bri_in,
    output logic [23:0] rgb_out
);
    logic [7:0] tab [16384];                // a ROM: 16 M10K blocks
    initial $readmemh({HEXDIR, "/k054573_dac.hex"}, tab);

    logic [23:0] c_q;
    logic  [5:0] b_q;
    logic        d_q;
    logic  [2:0] step;
    logic [13:0] addr;
    logic  [7:0] q, r_q, g_q;

    always_ff @(posedge clk) q <= tab[addr];

    always_ff @(posedge clk) begin
        if (cen_pix) begin
            c_q <= rgb_in; b_q <= bri_in[7:2]; d_q <= board_dac;
            step <= 3'd1;
        end else begin
            case (step)
                3'd1: begin addr <= {b_q, c_q[23:16]}; step <= 3'd2; end
                3'd2: begin addr <= {b_q, c_q[15:8]};  step <= 3'd3; end
                3'd3: begin addr <= {b_q, c_q[7:0]};   r_q <= q; step <= 3'd4; end
                3'd4: begin g_q <= q; step <= 3'd5; end
                3'd5: begin rgb_out <= d_q ? {r_q, g_q, q} : c_q; step <= 3'd0; end
                default: ;
            endcase
        end
    end
endmodule
