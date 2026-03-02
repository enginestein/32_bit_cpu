// general logic decoder is what takes a binary number, and turns it into a signal. A single signal.
// and this decoder, is an instruction decoder. which takes a big chunk of machine code, splits it into smaller pieces and sends it to the CPU to allocate regsters.



module decoder (
    
    input logic [31:0] instr, // The output instruction which we sent from our memory module, ROM.
    output logic [6:0] opcode, // tells the CPU which type of instruction it is, 7 bits wide.
    output logic [4:0] rd, // the desintation register, the place where the result of the opcode instruction will be stored.
    output logic [4:0] rs1, // source register 1, the two numbers which CPU will grab to sent to the ALU.
    output logic [4:0] rs2, // source register 2
    output logic [2:0] funct3, // some extra bits used to distniguish further between instructions.
    output logic [6:0] funct7
   
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off BLKSEQ */ 

// this part splits the instruction.
// lets say, the instr is 000000 00010 00001 000 00011 0110011
// opcode = 0110011
// rd = 00011
// funct3 = 000
// rs1 = 00001
// rs2 = 00010
// funct7 = 000000

    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign funct7 = instr[31:25];


endmodule
