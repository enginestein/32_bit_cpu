module control_unit  (
    input logic [6:0] opcode,
    output logic reg_we,
    output logic alu_src,
    output logic [1:0] alu_op,
    output logic mem_we,
    output logic mem_re,
    output logic mem_to_reg,
    output logic branch
    
);

    always_comb begin 
        mem_we = 0;
        mem_re = 0;
        mem_to_reg = 0;
        branch = 0;


        case (opcode) 
           7'b0110011: begin    // R-Type instruction
                reg_we = 1;
                alu_src = 0;
                alu_op = 2'b10; 
            end

            7'b1100111: begin // JALR
                reg_we = 1;
                alu_src = 1;
            end


            7'b1101111: begin // JAL
                reg_we = 1;
            end

            7'b1100011: begin // BRANCH
                alu_src = 0;
                alu_op  = 2'b01; // SUB
                branch  = 1;
            end

            7'b0010111: begin // AUIPC
                reg_we = 1;
                alu_src = 1;
                alu_op = 2'b00; // ADD
            end

            7'b0110111: begin // LUI
               reg_we = 1;
                alu_src = 1;
                alu_op = 2'b00; // ADD 
            end

            7'b0010011: begin // I-Type instruction
                reg_we = 1;
                alu_op = 2'b10;
                alu_src = 1;
            end

            7'b0000011: begin // LOAD WORD LW FROM DMEM
            reg_we = 1;
            alu_src = 1;
            alu_op  = 2'b00; // ADD for address
            mem_re = 1;
            mem_to_reg = 1;
            end

            7'b0100011: begin // STORE WORD SW FROM DMEM
                alu_src = 1;
                alu_op  = 2'b00; // ADD for address
                mem_we  = 1;
            end
        
            default: begin

            end
        endcase
    end

endmodule