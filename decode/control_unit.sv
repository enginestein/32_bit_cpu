/* 

    - Control Unit - 

    The control unit takes the opcode and returns important stuff 
    to the ALU Control unit. It determines what kind of opcode 
    it is and what part of the CPU should turn on and work.

*/

module control_unit (
    input  logic [6:0]  opcode,
    input  logic [31:0] instr,
    input  logic [2:0]  funct3,

    output logic        reg_we,
    output logic        alu_src,
    output logic [1:0]  alu_op,
    output logic        mem_we,
    output logic        mem_re,
    output logic        mem_to_reg,
    output logic [2:0]  mem_funct3,
    output logic        branch,

    output reg          trap,
    output reg  [3:0]   trap_cause
);


    always_comb begin

        // Defaults
        reg_we      = 0;
        alu_src     = 0;
        alu_op      = 2'b00;
        mem_we      = 0;
        mem_re      = 0;
        mem_to_reg  = 0;
        mem_funct3  = 3'b000;
        branch      = 0;
        trap        = 0;
        trap_cause  = 4'd0;

        case (opcode)

            7'b0110011: begin  // R-Type
                reg_we  = 1;
                alu_src = 0;
                alu_op  = 2'b10;
            end

            7'b1110011: begin  // SYSTEM / CSR
                case (funct3)

                    3'b000: begin
                        case (instr[31:20])

                            12'b000000000000: begin
                                trap       = 1;
                                trap_cause = 4'd11; // ECALL
                            end

                            12'b000000000001: begin
                                trap       = 1;
                                trap_cause = 4'd3;  // EBREAK
                            end

                            12'b001100000010: begin
                                // MRET (0x302)
                                // handled in cpu_top
                            end

                            default: begin
                                trap       = 1;
                                trap_cause = 4'd2;  // Illegal instruction
                            end
                        endcase
                    end

                    // CSR instructions
                    3'b001, // CSRRW
                    3'b010, // CSRRS
                    3'b011, // CSRRC
                    3'b101, // CSRRWI
                    3'b110, // CSRRSI
                    3'b111: begin // CSRRCI

                        reg_we = 1;
                    end

                    default: begin
                        trap       = 1;
                        trap_cause = 4'd2;
                    end

                endcase
            end

            7'b0001111: begin
                // FENCE / FENCE.I -> NOP
            end

            7'b1100111: begin  // JALR
                reg_we  = 1;
                alu_src = 1;
            end

            7'b1101111: begin  // JAL
                reg_we = 1;
            end

            7'b1100011: begin  // BRANCH
                alu_src = 0;
                alu_op  = 2'b01; // SUB
                branch  = 1;
            end

            7'b0010111: begin  // AUIPC
                reg_we  = 1;
                alu_src = 1;
                alu_op  = 2'b00; // ADD
            end

            7'b0110111: begin  // LUI
                reg_we  = 1;
                alu_src = 1;
                alu_op  = 2'b00; // ADD
            end

            7'b0010011: begin  // I-Type
                reg_we  = 1;
                alu_src = 1;
                alu_op  = 2'b10;
            end

            7'b0000011: begin  // LOAD
                reg_we      = 1;
                alu_src     = 1;
                alu_op      = 2'b00; // Address calculation
                mem_re      = 1;
                mem_to_reg  = 1;
                mem_funct3  = funct3;
            end

            7'b0100011: begin  // STORE
                alu_src     = 1;
                alu_op      = 2'b00; // Address calculation
                mem_we      = 1;
                mem_funct3  = funct3;
            end

            default: begin
                // do nothing
            end

        endcase
    end

endmodule
