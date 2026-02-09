module cpu_top (
    input  logic clk,
    input  logic reset,
    output logic [31:0] pc_dbg,
    output logic [31:0] dbg_x1,
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3
);

    logic [31:0] pc; // program counter
    logic [31:0] instr; // instructions
    assign pc_dbg = pc;
    logic [6:0] opcode; // type of instruction
    logic [4:0] rd, rs1, rs2;// the register destination and sources
    logic [2:0] funct3; // extra bits to distinguish between instructions
    logic [6:0] funct7; // extra bits to distinguish between instructions

    pc pc_u (
        .clk(clk),
        .reset(reset),
        .pc_out(pc)
    );

    imem imem_u (
        .addr(pc), 
        .instr(instr) // returns 000000 00010 00001 000 00011 0110011
    );

    decoder dec_u (
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7)
    );

    logic [31:0] imm;

    imm_gen imm_u (
        .instr(instr),
        .imm(imm)
    );

    logic [31:0] alu_out;

    alu alu_u (
        .a(rs1_val),
        .b(imm),
        .y(alu_out)
    );

    logic [31:0] rs1_val, rs2_val;
    logic reg_we;

    regfile rf_u (
        .clk(clk),
         .we(reg_we),
         .rs1(rs1),
         .rs2(rs2),
         .rd(rd),
         .wd(alu_out),
         .rd1(rs1_val),
         .rd2(rs2_val),
         .dbg_x1(dbg_x1),
        .dbg_x2(dbg_x2),
        .dbg_x3(dbg_x3)
    );

    always_comb begin 
        reg_we = 1'b0;

        if (opcode == 7'b0010011) 
            reg_we = 1'b1;
    end

// pc sends data -> sends that to imem to store -> then imem sends to decoder 

//PC updates (on clock edge)
//        ↓
//pc wire changes
//        ↓
//imem sees new addr
//        ↓
//instr wire changes
//        ↓
//decoder outputs change
//        ↓
//everything settles


// From the second update after I added ALU, regfile and the imm logic,
// firstly the program counter starts at 0 then points to imem,
// that at address 0 the machine code is 0000011012 etc. and that is the instruction which is returned by the imem.
// After that the instruction is sent to the decoder, which mainly returns rs1 and opcode respectively
// for regfile and ALU. the rs1 and rs2 are the register sources. Meanwhile the imm_gen extracts the constant number, the imm, from that instruction.
// Then the regfile takes the rs1 and rs2 and returns the values of those registers, rs1_val and rs2_val.
// Then the ALU takes the rs1_val and imm and returns the result of the operation.
// the always_comb block checks for the write enable safety switch. if the instruction is supposed to save a result.

// So, let's say the regfile give sthe value for rs1 as 5, and the imm generates the value as 10 so its sent to the ALU and ALU just does y = a + b
// which is 15 on the alu_out wire. The regfile then sees that we is 1
// so the switch for writing is on, it checks the value of alu_out and then it writes it into the rd, taking value from the wd. 
// which gives us dbg_x1 as 15. dbg_x2 and x3 are simply the other registers.



endmodule