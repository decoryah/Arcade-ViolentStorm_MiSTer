//------------------------------------------------------------------------------
// The board's player and coin input words from the MiSTer's controllers and keys.
//
// The game has three players (P1, P2, P3: the cabinet's DIP offers 2 or 3 players, its I/O CHECK screen has three
// columns, and nothing in the program ever reads the fourth player's byte at 274002), each with a joystick and two
// buttons, ATTACK and JUMP; its I/O CHECK screen lists no third button and holding one changes nothing in play (MAME's
// port definition has a third button per player from Konami's shared input macro). Three coin mechanisms: the coin
// byte is masked to bits 2:0.
//
// A MiSTer controller, the order of the J1 line in ViolentStorm.sv ("Attack,Jump,Start,Coin"):
//   bit 0 right, 1 left, 2 down, 3 up, 4 attack, 5 jump, 6 start, 7 coin
// A player's byte as the board carries it, active low (MAME's KONAMI16_LSB / MSB):
//   bit 0 left, 1 right, 2 up, 3 down, 4 button 1 (attack), 5 button 2 (jump), 6 button 3 (not on this cabinet: released),
//   7 start
//   274000: P1 low byte, P3 high byte;  274002: P2 low byte, P4 high byte (absent: released)
//   278000 low byte (IN0): coin 1-3 (bits 2:0), bit 3 unassigned (the fourth player's coin in MAME's table: masked off
//   by the game), service 1-3 (bits 6:4, read by the game as credits; not wired here) and bit 7 unassigned: all active low
//------------------------------------------------------------------------------
`default_nettype none

module vs_inputs (
    input  logic [7:0]  joy0, joy1, joy2,       // controllers 1-3
    input  logic [2:0]  key_start, key_coin,    // keyboard start / coin for players 1-3
    output logic [15:0] in_p1_p3,
    output logic [15:0] in_p2_p4,
    output logic [7:0]  in0
);
    function automatic logic [7:0] pbyte(input logic [7:0] j, input logic kstart);
        pbyte = ~{j[6] | kstart, 1'b0, j[5], j[4], j[2], j[3], j[0], j[1]};
    endfunction

    assign in_p1_p3 = {pbyte(joy2, key_start[2]), pbyte(joy0, key_start[0])};
    assign in_p2_p4 = {8'hff,                     pbyte(joy1, key_start[1])};
    assign in0      = ~{5'b00000, joy2[7] | key_coin[2], joy1[7] | key_coin[1], joy0[7] | key_coin[0]};
endmodule
