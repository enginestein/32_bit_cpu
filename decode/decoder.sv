/*

    - Binary Decoder -

    Here the instruction is taken from the imem, that instruction is taken by the decoder and gets split in various sub-instructions.
    These sub-instructions are used to tell the CPU what to do, where to do and how to do. It returns various logics, one major 
    logic is a 7 bit opcode which is the type of instruction the CPU has to execute.

*/

module decoder (
    
    input logic [31:0] instr, // The output instruction which we sent from our memory module, ROM.
    output logic [6:0] opcode, // tells the CPU which type of instruction it is, 7 bits wide.
    output logic [4:0] rd, // the desintation register, the place where the result of the opcode instruction will be stored.
    output logic [4:0] rs1, // source register 1, the two numbers which CPU will grab to sent to the ALU.
    output logic [4:0] rs2, // source register 2
    output logic [2:0] funct3, // some extra bits used to distniguish further between instructions.
    output logic [6:0] funct7,

    output logic is_r,
    output logic is_i,
    output logic is_load,
    output logic is_store,
    output logic is_branch,
    output logic is_jal,
    output logic is_jalr,
    output logic is_lui,
    output logic is_auipc,

    output logic uses_rs1,
    output logic uses_rs2,
    output logic writes_rd,

    output logic illegal
   
);


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

    assign is_r = (opcode == 7'b0110011);
    assign is_i = (opcode == 7'b0010011);
    assign is_load   = (opcode == 7'b0000011);
    assign is_store  = (opcode == 7'b0100011);
    assign is_branch = (opcode == 7'b1100011);
    assign is_jal    = (opcode == 7'b1101111);
    assign is_jalr   = (opcode == 7'b1100111);
    assign is_lui    = (opcode == 7'b0110111);
    assign is_auipc  = (opcode == 7'b0010111);

    assign uses_rs1 =
        is_r || is_i || is_load || is_store || is_branch || is_jalr;

    assign uses_rs2 =
        is_r || is_store || is_branch;

    assign writes_rd =
        is_r || is_i || is_load || is_jal || is_jalr || is_lui || is_auipc;

    assign illegal = !(is_r || is_i || is_load || is_store ||
        is_branch || is_jal || is_jalr ||
            is_lui || is_auipc);



endmodule
