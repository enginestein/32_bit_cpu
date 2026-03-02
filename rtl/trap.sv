module trap(
    input clk,
    input trap,
    input [3:0] trap_cause,
    input [31:0] pc_current,
    input [31:0] pc_normal_next,

    output reg [31:0] pc_next
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off PINMISSING */
/* verilator lint_off UNDRIVEN */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off BLKSEQ */

reg [31:0] mtvec = 32'h00000100;
reg [31:0] mepc;
reg [31:0] mcause;

always_comb begin
    if (trap) begin
        pc_next = mtvec;
    end else begin
        pc_next = pc_normal_next;
    end
end

always_ff @(posedge clk) begin
    if (trap) begin
        mepc   <= pc_current;
        mcause <= {28'b0, trap_cause};
    end
end

endmodule
