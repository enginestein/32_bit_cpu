/*
    - ALU -

    Performs single-cycle arithmetic and logic operations.

    Multiply / divide / remainder operations (alu_control >= 5'b01110) are
    NOT handled here — they are routed to muldiv_unit.sv, which is a
    separate multi-cycle unit.  Any muldiv alu_control value will hit the
    default branch and produce 32'd0; cpu_top.sv ensures those results are
    never used (the pipeline is stalled until muldiv_unit signals ready).
*/

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [4:0]  alu_control,
    output logic [31:0] y
);


    always_comb begin
        case (alu_control)
            5'b00000: y = a + b;                                             // ADD
            5'b00001: y = a - b;                                             // SUB
            5'b00010: y = a & b;                                             // AND
            5'b00011: y = a | b;                                             // OR
            5'b00100: y = a ^ b;                                             // XOR
            5'b00101: y = a << b[4:0];                                        // SLL
            5'b00110: y = a >> b[4:0];                                        // SRL
            5'b00111: y = a >>> b[4:0];                                       // SRA (arithmetic)
            5'b01000: y = ($signed(a) <  $signed(b)) ? 32'd1 : 32'd0;        // SLT
            5'b01001: y = (a < b)                    ? 32'd1 : 32'd0;        // SLTU / SLTIU

            // branch units handled by branch_unit

            /*
            5'b01010: y = (a == b)                   ? 32'd1 : 32'd0;        // BEQ
            5'b01011: y = (a != b)                   ? 32'd1 : 32'd0;        // BNE
            5'b01100: y = ($signed(a) >= $signed(b)) ? 32'd1 : 32'd0;        // BGE
            5'b01101: y = ($signed(a) >  $signed(b)) ? 32'd1 : 32'd0;        // BGT 
            */

            // 5'b01110 – 5'b10101: MUL / DIV family -> handled by muldiv_unit
            default:  y = 32'd0;
        endcase
    end

endmodule
