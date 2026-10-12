// K055550 unit bench: the chip on a behavioural bus (a 16 MB byte-addressed RAM, the protocol of rtl/vs_main.sv:
// an access is answered by m_done two clocks after m_go -- a write is done in the clock after the strobe, a read
// likewise with m_rd). The C++ side programs the registers as the 68000 would and compares memory and registers
// with a transcription of MAME's K055550_word_w (sim/tb_k550.cpp).
`default_nettype none

module tb_k550_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        wr,
    input  logic  [4:0] idx,
    input  logic  [1:0] be,
    input  logic [15:0] wdata,
    input  logic  [4:0] rd_idx,
    output logic [15:0] rd_q,
    output logic        busy,
    output logic [31:0] n_access
);
    logic        m_go, m_we, m_done;
    logic [23:1] m_a;
    logic  [1:0] m_be;
    logic [15:0] m_wd, m_rd;
    logic [15:0] mem [0:(1 << 23) - 1] /*verilator public_flat_rw*/;

    k055550 #(.HEXDIR("../rtl/data")) u_dut (
        .clk(clk), .reset(reset), .wr(wr), .idx(idx), .be(be), .wdata(wdata), .rd_idx(rd_idx), .rd_q(rd_q), .busy(busy),
        .m_go(m_go), .m_we(m_we), .m_a(m_a), .m_be(m_be), .m_wd(m_wd), .m_done(m_done), .m_rd(m_rd)
    );

    // the bus: the access happens in the strobe's clock, the answer comes in the next
    always_ff @(posedge clk) begin
        m_done <= 1'b0;
        if (reset) n_access <= '0;
        if (m_go) begin
            n_access <= n_access + 32'd1;
            if (m_we) begin
                if (m_be[1]) mem[m_a][15:8] <= m_wd[15:8];
                if (m_be[0]) mem[m_a][7:0]  <= m_wd[7:0];
            end else m_rd <= mem[m_a];
            m_done <= 1'b1;
        end
    end
endmodule
