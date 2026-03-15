/*
    - ALU Control Unit -

    Returns the alu_control to the ALU, the ALU takes this logic to identify what Operation it has to perform. While this works 
    on the bases of the alu_op which comes from the control unit.
*/

module alu_control_unit (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [4:0] alu_control
);


    always_comb begin
        case (alu_op)

            2'b00: 
                alu_control = 5'b00000; // add (loads/stores)

            2'b01: begin
                case (funct3)
                    3'b000,
                    3'b001: alu_control = 5'b00001; // BEQ/BNE use SUB

                    3'b100,
                    3'b101: alu_control = 5'b01000; // BLT/BGE use SLT

                    3'b110,
                    3'b111: alu_control = 5'b01001; // BLTU/BGEU use SLTU

                    default: alu_control = 5'b00001;
                endcase
            end

            2'b10: begin
                if (funct7 == 7'b0000001) begin
                    case (funct3)
                        3'b000: alu_control = 5'b01110; // MUL
                        3'b001: alu_control = 5'b01111; // MULH
                        3'b010: alu_control = 5'b10000; // MULHSU
                        3'b011: alu_control = 5'b10001; // MULHU
                        3'b100: alu_control = 5'b10010; // DIV
                        3'b101: alu_control = 5'b10011; // DIVU
                        3'b110: alu_control = 5'b10100; // REM
                        3'b111: alu_control = 5'b10101; // REMU
                        default: alu_control = 5'b00000;
                    endcase
                end 
                else begin
                    case (funct3)
                        3'b000: begin
                            if (funct7 == 7'b0100000)
                                alu_control = 5'b00001; // SUB
                            else
                                alu_control = 5'b00000; // ADD / ADDI
                        end

                        3'b111: alu_control = 5'b00010;
                        3'b110: alu_control = 5'b00011;
                        3'b100: alu_control = 5'b00100;
                        3'b010: alu_control = 5'b01000;
                        3'b011: alu_control = 5'b01001;
                        3'b001: alu_control = 5'b00101;
                        3'b101: alu_control = (funct7 == 7'b0100000) ? 
                                              5'b00111 : 
                                              5'b00110;

                        default: alu_control = 5'b00000;
                    endcase
                end
            end

            default: 
                alu_control = 5'b00000;

        endcase
    end

endmodule
