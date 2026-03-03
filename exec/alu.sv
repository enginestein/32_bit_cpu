/*

    - ALU -

    The unit which simply performs the math

*/

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [4:0]  alu_control,
    output logic [31:0] y
);

    /* verilator lint_off EOFNEWLINE */
    /* verilator lint_off PROCASSINIT */
    /* verilator lint_off BLKSEQ */

    always_comb begin
        case (alu_control)

            5'b00000: y = a + b;                                   // ADD
            5'b00001: y = a - b;                                   // SUB
            5'b00010: y = a & b;                                   // AND
            5'b00011: y = a | b;                                   // OR
            5'b00100: y = a ^ b;                                   // XOR
            5'b00101: y = a << b[4:0];                              // SLL
            5'b00110: y = a >> b[4:0];                              // SRL
            5'b00111: y = a >>> b[4:0];                             // SRA
            5'b01000: y = ($signed(a) <  $signed(b)) ? 32'd1 : 32'd0; // SLT
            5'b01001: y = (a < b) ? 32'd1 : 32'd0;                  // SLTU / SLTIU
            5'b01010: y = (a == b) ? 32'd1 : 32'd0;                 // BEQ
            5'b01011: y = (a != b) ? 32'd1 : 32'd0;                 // BNE
            5'b01100: y = ($signed(a) >= $signed(b)) ? 32'd1 : 32'd0;
            5'b01101: y = ($signed(a) >  $signed(b)) ? 32'd1 : 32'd0;
            5'b01110: y = a * b;                                    // MUL
            5'b01111: y = ($signed(a) * $signed(b)) >>> 32;          // MULH
            5'b10000: y = ($signed(a) * b) >>> 32;                   // MULHSU
            5'b10001: y = (a * b) >>> 32;                            // MULHU
            5'b10010: y = (b != 0) ? $signed(a) / $signed(b) 
                                   : 32'hFFFFFFFF;                   // DIV
            5   'b10011: y = (b != 0) ? a / b 
                                   : 32'hFFFFFFFF;                   // DIVU
            5'b10100: y = (b != 0) ? $signed(a) % $signed(b) 
                                   : a;                              // REM
            5'b10101: y = (b != 0) ? a % b 
                                   : a;                              // REMU

            default: y = 32'd0;

        endcase
    end

endmodule
