// vs_inputs against the decode the core had before the J1 line lost its third button and the fourth player went
// (Button 1-3, Start, Coin = pad bits 4-8, four controllers, four start / coin keys), and against a table written from the
// cabinet's names. Exhaustive per controller (256 pad values x the start key x the coin key, the others idle), then
// a million random vectors of all controllers and keys; plus directed checks of every pad bit's board bit.
//   sim/inputs/run.sh
`timescale 1ns/1ps
module tb_vs_inputs;
    logic [7:0]  joy0, joy1, joy2;
    logic [2:0]  key_start, key_coin;
    wire  [15:0] in_p1_p3, in_p2_p4;
    wire  [7:0]  in0;
    vs_inputs dut (.joy0(joy0), .joy1(joy1), .joy2(joy2), .key_start(key_start), .key_coin(key_coin),
                   .in_p1_p3(in_p1_p3), .in_p2_p4(in_p2_p4), .in0(in0));

    integer errors = 0, checks = 0;

    // ---- the previous decode (ViolentStorm.sv before this change), on the previous pad layout ----
    function automatic [7:0] old_pbyte(input [31:0] j, input kstart);
        old_pbyte = ~{j[7] | kstart, j[6], j[5], j[4], j[2], j[3], j[0], j[1]};
    endfunction
    // the new pad vector in the old layout: directions as they were, attack 4, jump 5, button 3 (6) never pressed, start 7, coin 8
    function automatic [31:0] to_old(input [7:0] j);
        to_old = {23'd0, j[7], j[6], 1'b0, j[5], j[4], j[3:0]};
    endfunction

    // ---- a table from the cabinet's names: pad bit -> board bit ----
    localparam PAD_RIGHT = 0, PAD_LEFT = 1, PAD_DOWN = 2, PAD_UP = 3, PAD_ATTACK = 4, PAD_JUMP = 5, PAD_START = 6, PAD_COIN = 7;
    localparam B_LEFT = 0, B_RIGHT = 1, B_UP = 2, B_DOWN = 3, B_ATTACK = 4, B_JUMP = 5, B_BTN3 = 6, B_START = 7;
    function automatic [7:0] ref_player(input [7:0] j, input ks);
        reg [7:0] r;
        begin
            r = 8'hff;                                  // everything released (active low)
            if (j[PAD_RIGHT])  r[B_RIGHT]  = 1'b0;
            if (j[PAD_LEFT])   r[B_LEFT]   = 1'b0;
            if (j[PAD_DOWN])   r[B_DOWN]   = 1'b0;
            if (j[PAD_UP])     r[B_UP]     = 1'b0;
            if (j[PAD_ATTACK]) r[B_ATTACK] = 1'b0;
            if (j[PAD_JUMP])   r[B_JUMP]   = 1'b0;
            if (j[PAD_START] | ks) r[B_START] = 1'b0;
            ref_player = r;                             // button 3 (bit 6) stays released
        end
    endfunction

    task automatic check(input [255:0] what);
        reg [15:0] e13, e24;
        reg  [7:0] e0, o0;
        reg [15:0] o13, o24;
        reg [31:0] oj0, oj1, oj2;
        begin
            oj0 = to_old(joy0); oj1 = to_old(joy1); oj2 = to_old(joy2);
            e13 = {ref_player(joy2, key_start[2]), ref_player(joy0, key_start[0])};
            e24 = {8'hff, ref_player(joy1, key_start[1])};
            e0  = ~{5'b00000, joy2[PAD_COIN] | key_coin[2], joy1[PAD_COIN] | key_coin[1], joy0[PAD_COIN] | key_coin[0]};
            // the old decode, the fourth controller and its keys idle
            o13 = {old_pbyte(oj2, key_start[2]), old_pbyte(oj0, key_start[0])};
            o24 = {old_pbyte(32'd0, 1'b0), old_pbyte(oj1, key_start[1])};
            o0  = ~{2'b00, 2'b00, 1'b0, oj2[8] | key_coin[2], oj1[8] | key_coin[1], oj0[8] | key_coin[0]};
            checks = checks + 1;
            if (in_p1_p3 !== e13 || in_p2_p4 !== e24 || in0 !== e0 || in_p1_p3 !== o13 || in_p2_p4 !== o24 || in0 !== o0) begin
                errors = errors + 1;
                if (errors < 20)
                    $display("MISMATCH (%0s): joy %02x %02x %02x keys s%b c%b : p1p3 %04x (table %04x old %04x) p2p4 %04x (%04x %04x) in0 %02x (%02x %02x)",
                             what, joy0, joy1, joy2, key_start, key_coin, in_p1_p3, e13, o13, in_p2_p4, e24, o24, in0, e0, o0);
            end
        end
    endtask

    // one pad bit pressed on controller `p` (0..2) must clear exactly one board bit
    task automatic directed(input integer p, input integer padbit, input integer word, input integer bit_in_word, input is_coin);
        reg [15:0] w13, w24; reg [7:0] w0;
        begin
            joy0 = 0; joy1 = 0; joy2 = 0; key_start = 0; key_coin = 0;
            case (p) 0: joy0[padbit] = 1; 1: joy1[padbit] = 1; default: joy2[padbit] = 1; endcase
            #1;
            checks = checks + 1;
            if (is_coin) begin
                if (in0 !== ~(8'd1 << p) || in_p1_p3 !== 16'hffff || in_p2_p4 !== 16'hffff) begin
                    errors = errors + 1; $display("DIRECTED coin: controller %0d bit %0d: in0 %02x p1p3 %04x p2p4 %04x", p, padbit, in0, in_p1_p3, in_p2_p4);
                end
            end else begin
                w13 = 16'hffff; w24 = 16'hffff;
                if (word == 0) w13[bit_in_word] = 1'b0; else w24[bit_in_word] = 1'b0;
                if (in_p1_p3 !== w13 || in_p2_p4 !== w24 || in0 !== 8'hff) begin
                    errors = errors + 1; $display("DIRECTED: controller %0d bit %0d: p1p3 %04x (want %04x) p2p4 %04x (want %04x) in0 %02x",
                                                  p, padbit, in_p1_p3, w13, in_p2_p4, w24, in0);
                end
            end
        end
    endtask

    integer i, p, v, ks, kc, seed;
    reg [31:0] r;
    initial begin
        joy0 = 0; joy1 = 0; joy2 = 0; key_start = 0; key_coin = 0;
        #1;
        // idle: every board bit released
        checks = checks + 1;
        if (in_p1_p3 !== 16'hffff || in_p2_p4 !== 16'hffff || in0 !== 8'hff) begin errors = errors + 1; $display("idle: not all released"); end

        // directed: pad bit -> board bit, per controller (controller 0 = P1: p1p3 low byte; 1 = P2: p2p4 low byte; 2 = P3: p1p3 high byte)
        for (p = 0; p < 3; p = p + 1) begin
            // word 0 = in_p1_p3, word 1 = in_p2_p4; base bit 0 or 8
            directed(p, PAD_LEFT,   (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_LEFT,   0);
            directed(p, PAD_RIGHT,  (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_RIGHT,  0);
            directed(p, PAD_UP,     (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_UP,     0);
            directed(p, PAD_DOWN,   (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_DOWN,   0);
            directed(p, PAD_ATTACK, (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_ATTACK, 0);
            directed(p, PAD_JUMP,   (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_JUMP,   0);
            directed(p, PAD_START,  (p == 1) ? 1 : 0, ((p == 2) ? 8 : 0) + B_START,  0);
            directed(p, PAD_COIN,   0, 0, 1);
        end

        // exhaustive per controller, the others idle, every start / coin key state
        for (p = 0; p < 3; p = p + 1)
            for (v = 0; v < 256; v = v + 1)
                for (ks = 0; ks < 8; ks = ks + 1)
                    for (kc = 0; kc < 8; kc = kc + 1) begin
                        joy0 = 0; joy1 = 0; joy2 = 0;
                        case (p) 0: joy0 = v; 1: joy1 = v; default: joy2 = v; endcase
                        key_start = ks; key_coin = kc;
                        #1; check("exhaustive");
                    end

        // random: all controllers and keys at once
        seed = 32'h1234abcd;
        for (i = 0; i < 1000000; i = i + 1) begin
            r = $random(seed); joy0 = r[7:0]; joy1 = r[15:8]; joy2 = r[23:16]; key_start = r[26:24]; key_coin = r[29:27];
            #1; check("random");
        end

        if (errors == 0) $display("PASS: %0d checks, 0 mismatches", checks);
        else $display("FAIL: %0d of %0d checks", errors, checks);
        $finish;
    end
endmodule
