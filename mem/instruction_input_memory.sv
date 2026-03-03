module instruction_input_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off BLKSEQ */

logic [31:0] mem [0:255];

initial begin

    // ===============================
    // BASIC REGISTER INIT
    // ===============================

    mem[0]  = 32'h00500093; // addi x1, x0, 5
    mem[1]  = 32'h00A00113; // addi x2, x0, 10
    mem[2]  = 32'hFFF00193; // addi x3, x0, -1

    // ===============================
    // R-TYPE
    // ===============================

    mem[3]  = 32'h002081B3; // add  x3,x1,x2
    mem[4]  = 32'h40208233; // sub  x4,x1,x2
    mem[5]  = 32'h0020F2B3; // and  x5,x1,x2
    mem[6]  = 32'h0020E333; // or   x6,x1,x2
    mem[7]  = 32'h0020C3B3; // xor  x7,x1,x2
    mem[8]  = 32'h00209433; // sll  x8,x1,x2
    mem[9]  = 32'h0020D4B3; // srl  x9,x1,x2
    mem[10] = 32'h4020D533; // sra  x10,x1,x2
    mem[11] = 32'h0020A5B3; // slt  x11,x1,x2
    mem[12] = 32'h0020B633; // sltu x12,x1,x2

    // ===============================
    // I-TYPE
    // ===============================

    mem[13] = 32'h00408693; // addi x13,x1,4
    mem[14] = 32'h0020F713; // andi x14,x1,2
    mem[15] = 32'h0030E793; // ori  x15,x1,3
    mem[16] = 32'h0010C813; // xori x16,x1,1
    mem[17] = 32'h00209493; // slli x9,x1,2
    mem[18] = 32'h0020D913; // srli x18,x1,2
    mem[19] = 32'h4020D993; // srai x19,x1,2
    mem[20] = 32'h0020AA13; // slti x20,x1,2
    mem[21] = 32'h0020BA93; // sltiu x21,x1,2

    // ===============================
    // M EXTENSION
    // ===============================

    mem[22] = 32'h022081B3; // mul
    mem[23] = 32'h022091B3; // mulh
    mem[24] = 32'h0220A1B3; // mulhsu
    mem[25] = 32'h0220B1B3; // mulhu
    mem[26] = 32'h0220C1B3; // div
    mem[27] = 32'h0220D1B3; // divu
    mem[28] = 32'h0220E1B3; // rem
    mem[29] = 32'h0220F1B3; // remu

    // ===============================
    // MEMORY TEST
    // ===============================

    mem[30] = 32'h00202023; // sw x2,0(x0)
    mem[31] = 32'h00002103; // lw x2,0(x0)

    mem[32] = 32'h00200023; // sb x2,0(x0)
    mem[33] = 32'h00000283; // lb x5,0(x0)
    mem[34] = 32'h00004303; // lbu x6,0(x0)

    // misaligned store (should flag)
    mem[35] = 32'h00202123; // sw x2,2(x0)

    // ===============================
    // BRANCHES
    // ===============================

    mem[36] = 32'h00208663; // beq x1,x2,+8
    mem[37] = 32'h00209663; // bne x1,x2,+8
    mem[38] = 32'h0020C663; // blt x1,x2,+8
    mem[39] = 32'h0020D663; // bge x1,x2,+8
    mem[40] = 32'h0020E663; // bltu x1,x2,+8
    mem[41] = 32'h0020F663; // bgeu x1,x2,+8

    // ===============================
    // JAL / JALR
    // ===============================

    mem[42] = 32'h004000EF; // jal x1,+4
    mem[43] = 32'h00008067; // jalr x0,x1,0

    // ===============================
    // LUI / AUIPC
    // ===============================

    mem[44] = 32'h0000B537; // lui x10,0xB
    mem[45] = 32'h0000B517; // auipc x10,0xB

    // ===============================
    // TRAPS
    // ===============================

    mem[46] = 32'h00000073; // ecall
    mem[47] = 32'h00100073; // ebreak
    mem[48] = 32'hFFFFFFFF; // illegal instruction

end

assign instr = mem[addr[9:2]];

endmodule
