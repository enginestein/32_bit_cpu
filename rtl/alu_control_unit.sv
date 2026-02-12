module alu_control_unit (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_control
);

    always_comb begin
        case (alu_op)
            2'b00: alu_control = 4'b0000; // add (loads/stores later)
            2'b01: alu_control = 4'b0001; // sub (branches later)

            2'b10: begin // R-type or I-type arithmetic
                case (funct3)
                    3'b000: alu_control = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000; // sub/add
                    3'b111: alu_control = 4'b0010; // and
                    3'b110: alu_control = 4'b0011; // or
                    3'b100: alu_control = 4'b0100; // xor
                    3'b001: alu_control = 4'b0101; // sll
                    3'b101: alu_control = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // sra/srl
                    default: alu_control = 4'b0000;
                endcase
            end

            default: alu_control = 4'b0000;
        endcase
    end
endmodule
