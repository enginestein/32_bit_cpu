module pc (
    input logic clk,
    input logic reset,
    input logic [31:0] pc_next,
    output logic [31:0] pc_out
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off PINMISSING */
/* verilator lint_off UNDRIVEN */
/* verilator lint_off IMPLICIT */
/* verilator lint_off BLKSEQ */

always_ff @(posedge clk) begin
    if (reset)
        pc_out <= 32'd0;
    else
        pc_out <= pc_next;
end

endmodule
