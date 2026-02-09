module imm_gen (
    input logic [31:0] instr,
    output logic [31:0] imm
);


    // this is sent to the ALU. This extracts the immediate value from the instruction. 
    assign imm = {{20{instr[31]}}, instr[31:20]};

endmodule