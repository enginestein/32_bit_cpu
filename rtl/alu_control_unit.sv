/*
    - ALU Control Unit -
*/

module alu_control_unit (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_control
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off BLKSEQ */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off LATCH */

    always_comb begin
        case (alu_op)
            2'b00: alu_control = 4'b0000; // add (loads/stores)

            2'b01: begin
                case (funct3)
                    3'b000, 3'b001: alu_control = 4'b0001; // BEQ/BNE use SUB
                    3'b100, 3'b101: alu_control = 4'b1000; // BLT/BGE use SLT
                    3'b110, 3'b111: alu_control = 4'b1001; // BLTU/BGEU use SLTU
                    default:        alu_control = 4'b0001;
                endcase
            end

            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'b0001; // SUB
                        else
                            alu_control = 4'b0000; // ADD / ADDI
                    end
                    3'b111: alu_control = 4'b0010; // AND / ANDI
                    3'b110: alu_control = 4'b0011; // OR  / ORI
                    3'b100: alu_control = 4'b0100; // XOR / XORI
                    3'b010: alu_control = 4'b1000; // SLT / SLTI
                    3'b011: alu_control = 4'b1001; // SLTU / SLTIU
                    3'b001: alu_control = 4'b0101; // SLL / SLLI
                    3'b101: alu_control = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // SRA/SRL
                    default: alu_control = 4'b0000;
                endcase
            end

            default: alu_control = 4'b0000;
        endcase
    end
endmodule
