module cpu_top (
    input  logic clk,
    input  logic reset,
    output logic [31:0] pc_dbg,
    output logic [31:0] dbg_x1,
    output logic [31:0] dbg_mem0,
output logic [31:0] dbg_mem4,
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3
);
/* verilator lint_off EOFNEWLINE */
/* verilator lint_off PROCASSINIT */
/* verilator lint_off PINMISSING */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off UNDRIVEN */
/* verilator lint_off IMPLICIT */
/* verilator lint_off BLKSEQ */
    logic alu_src;
logic [1:0] alu_op;
    logic [31:0] alu_b;
    logic [3:0] alu_control;
    logic [31:0] pc; // program counter
    logic [31:0] instr; // instructions
    assign pc_dbg = pc;
    logic [6:0] opcode; // type of instruction
    logic [4:0] rd, rs1, rs2;// the register destination and sources
    logic [2:0] funct3; // extra bits to distinguish between instructions
    logic [6:0] funct7; // extra bits to distinguish between instructions
    logic mem_we, mem_re, mem_to_reg;
    logic [2:0] mem_funct3;
    logic trap;
logic [3:0] trap_cause;
logic [31:0] pc_next;
    logic [31:0] mem_data;
    logic misaligned;
logic branch;
logic branch_taken;
logic [31:0] branch_target;


assign dbg_mem0 = dmem.mem[0];
assign dbg_mem4 = dmem.mem[1]; // because word index 1 = address 4
    integer cycle = 0;

function string alu_op_name(input logic [3:0] ctrl);
    case (ctrl)
        4'b0000: alu_op_name = "ADD";
        4'b0001: alu_op_name = "SUB";
        4'b0010: alu_op_name = "AND";
        4'b0011: alu_op_name = "OR";
        4'b0100: alu_op_name = "XOR";
        4'b0101: alu_op_name = "SLL";
        4'b0110: alu_op_name = "SRL";
        4'b0111: alu_op_name = "SRA";
        4'b1000: alu_op_name = "SLT";
        4'b1001: alu_op_name = "SLTU";
        4'b1010: alu_op_name = "BEQ";
        4'b1011: alu_op_name = "BNE";
        4'b1100: alu_op_name = "BGE";
        4'b1101: alu_op_name = "BGT";
        default: alu_op_name = "UNKNOWN";
    endcase
endfunction

pc pc_u (
    .clk(clk),
    .reset(reset),
    .pc_next(pc_next),
    .pc_out(pc)
);


    instruction_input_memory imem_u (
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

    logic jal;
    assign jal = (opcode == 7'b1101111);

    logic jalr;
    assign jalr = (opcode == 7'b1100111);

   assign branch_taken = jal || jalr || (branch && (
    (funct3 == 3'b000 && alu_out == 32'd0)  ||  // BEQ
    (funct3 == 3'b001 && alu_out != 32'd0)  ||  // BNE
    (funct3 == 3'b100 && alu_out == 32'd1)  ||  // BLT
    (funct3 == 3'b101 && alu_out == 32'd0)  ||  // BGE
    (funct3 == 3'b110 && alu_out == 32'd1)  ||  // BLTU
    (funct3 == 3'b111 && alu_out == 32'd0)      // BGEU
));

    assign branch_target =
    jal  ? (pc + imm) :
    jalr ? ((rs1_val + imm) & 32'hFFFFFFFE) :
    (pc + imm);


    assign alu_b = (alu_src) ? imm : rs2_val;

    logic [31:0] alu_out;

control_unit ctrl_u (
    .opcode(opcode),
    .instr(instr),
    .funct3(funct3),
    .reg_we(reg_we),
    .alu_src(alu_src),
    .alu_op(alu_op),
    .mem_we(mem_we),
    .mem_re(mem_re),
    .mem_to_reg(mem_to_reg),
    .mem_funct3(mem_funct3),
    .branch(branch),
    .trap(trap),
    .trap_cause(trap_cause)
);


    dmem dmem(
        .clk(clk),
        .we(mem_we),
        .funct3(funct3),
        .misaligned(misaligned),
        .addr(alu_out),
        .re(mem_re),
        .wd(rs2_val),
        .rd(mem_data)
    );

alu_control_unit alu_ctrl_u (
    .alu_op(alu_op),
    .funct3(funct3),
    .funct7(funct7),
    .alu_control(alu_control)
);

trap trap_u (
    .clk(clk),
    .trap(trap),
    .trap_cause(trap_cause),
    .pc_current(pc),
    .pc_normal_next(next_pc),
    .pc_next(pc_next)
);

    logic [31:0] alu_a;
    assign alu_a = (opcode == 7'b0110111) ? 32'd0 : (opcode == 7'b0010111) ? pc : rs1_val;

    alu alu_u (
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control),
        .y(alu_out)
    );

    logic [31:0] rs1_val, rs2_val;
    logic reg_we;

    logic [31:0] writeback_data;
    assign writeback_data =
    (jal || jalr) ? (pc + 32'd4) :
    (mem_to_reg) ? mem_data :
    alu_out;

logic reg_we_final;

assign reg_we_final = trap ? 1'b0 : reg_we;

    regfile rf_u (
        .clk(clk),
         .rs1(rs1),
         .rs2(rs2),
         .rd(rd),
        .wd(writeback_data),
.we(reg_we_final),
         .rd1(rs1_val),
         .rd2(rs2_val),
         .dbg_x1(dbg_x1),
        .dbg_x2(dbg_x2),
        .dbg_x3(dbg_x3)
    );


logic [31:0] next_pc;
assign next_pc = branch_taken ? branch_target : (pc + 32'd4);


always @(posedge clk) begin
    cycle++;

    $display("");
    $display("======================================================================");
    $display("                      CYCLE %0d", cycle);
    $display("======================================================================");

    if (misaligned) begin
        $display("==========================================");
        $display(" MISALIGNED MEMORY ACCESS DETECTED ");
        $display(" funct3  : %03b", funct3);
        $display("==========================================");
    end


    // ---------------- PC ----------------
    $display("PC STAGE");
    $display("  PC (hex) : 0x%08h", pc);
    $display("  PC (dec) : %0d", pc);
    $display("  PC (bin) : %032b", pc);
    $display("");

    // ---------------- FETCH ----------------
    $display("FETCH STAGE");
    $display("  Instruction (hex) : 0x%08h", instr);
    $display("  Instruction (bin) : %032b", instr);
    $display("");

    // ---------------- DECODE ----------------
    $display("DECODE STAGE");
    $display("  opcode : %07b (0x%02h)", opcode, opcode);
    $display("  rd     : x%0d", rd);
    $display("  rs1    : x%0d", rs1);
    $display("  rs2    : x%0d", rs2);
    $display("  funct3 : %03b", funct3);
    $display("  funct7 : %07b", funct7);
    $display("");

    // ---------------- CONTROL ----------------
    $display("CONTROL SIGNALS");
    $display("  reg_we     : %b", reg_we);
    $display("  alu_src    : %b (%s)", 
                alu_src, 
                alu_src ? "Using Immediate" : "Using rs2");
    $display("  alu_op     : %02b", alu_op);
    $display("  alu_ctrl   : %04b (%s)", 
                alu_control, 
                alu_op_name(alu_control));
    $display("");

    // ---------------- REGISTER READ ----------------
    $display("REGISTER FILE READ");
    $display("  rs1 (x%0d) value : %0d (0x%08h) (%032b)", 
                rs1, rs1_val, rs1_val, rs1_val);
    $display("  rs2 (x%0d) value : %0d (0x%08h) (%032b)", 
                rs2, rs2_val, rs2_val, rs2_val); 
    $display("");

    // ---------------- IMMEDIATE ----------------
    $display("IMMEDIATE GENERATOR");
    $display("  imm value : %0d (0x%08h) (%032b)", 
                imm, imm, imm);
    $display("");

    // ---------------- ALU ----------------
    $display("ALU EXECUTION");
    $display("  ALU input A : %0d (0x%08h)", alu_a, alu_a);
    $display("  ALU input B : %0d (0x%08h)", alu_b, alu_b);
    $display("  Operation   : %s", alu_op_name(alu_control));
    $display("  ALU result  : %0d (0x%08h) (%032b)", 
                alu_out, alu_out, alu_out);
    $display("");

    // ---------------- WRITEBACK ----------------
    $display("WRITEBACK STAGE");
    if (reg_we)
        $display("  Writing %0d (0x%08h) to register x%0d",
                writeback_data, writeback_data, rd);
    else
        $display("  No register write this cycle");


    $display("");

    // ---------------- CONTROL FLOW ----------------
    $display("CONTROL FLOW");
    $display("  jal          : %b", jal);
    $display("  jalr         : %b", jalr);
    $display("  branch       : %b", branch);
    $display("  branch_taken : %b", branch_taken);
    $display("  branch_target: 0x%08h", branch_target);
    $display("");

    // ---------------- MEMORY ----------------
    $display("MEMORY STAGE");
    $display("  mem_we     : %b", mem_we);
    $display("  mem_re     : %b", mem_re);
    $display("  mem_to_reg : %b", mem_to_reg);
    $display("  mem_data   : %0d (0x%08h)", mem_data, mem_data);
    $display("");



    // ---------------- REGISTER SNAPSHOT ----------------
$display("REGISTER SNAPSHOT");
$display("  x1 : %0d", rf_u.regs[1]);
$display("  x2 : %0d", rf_u.regs[2]);
$display("  x3 : %0d", rf_u.regs[3]);

    $display("  Next PC     : %0d ", next_pc);
    $display("======================================================================");
end

endmodule
