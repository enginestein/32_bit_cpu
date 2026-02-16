module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_control,
    output logic [31:0] y
);

    always_comb begin 
        case (alu_control)

            4'b0000: y = a + b;
            4'b0001: y = a - b;
            4'b0010: y = a & b;
            4'b0011: y = a | b;
            4'b0100: y = a ^ b;
            4'b0101: y = a << b;
            4'b0110: y = a >> b;
            4'b0111: y = a >>> b;

            4'b1000: y = ($signed(a) <  $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1001: y = ($signed(a) <= $signed(b)) ? 32'd1 : 32'd0;
            4'b1010: y = (a == b) ? 32'd1 : 32'd0; // EQ
            4'b1011: y = (a != b) ? 32'd1 : 32'd0;
            4'b1100: y = ($signed(a) >= $signed(b)) ? 32'd1 : 32'd0;
            4'b1101: y = ($signed(a) >  $signed(b)) ? 32'd1 : 32'd0; // GT

            default: y = 32'd0;

        endcase 
    end

endmodule
