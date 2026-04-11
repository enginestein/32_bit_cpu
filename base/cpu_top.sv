module cpu_top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] pc_dbg,
    output logic [31:0] dbg_x1,
    output logic [31:0] dbg_mem0,
    output logic [31:0] dbg_mem4,
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3,
    output logic        dbg_stall,   // HIGH while a multi-cycle op is in progress
    output logic uart_tx
);


    /* verilator lint_off WIDTH */
    /* verilator lint_off CASEINCOMPLETE */
    /* verilator lint_off BLKSEQ */

    logic        alu_src;
    logic [1:0]  alu_op;
    logic [31:0] alu_b;
    logic [4:0]  alu_control;
    logic [31:0] pc;
    logic [31:0] instr;

    logic branch_taken_internal;

    assign pc_dbg = pc;

    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic is_r;
    logic is_i;
    logic is_load;
    logic is_store;
    logic is_branch;
    logic is_jal;
    logic is_jalr;
    logic is_lui;
    logic is_auipc;
    logic uses_rs1;
    logic uses_rs2;
    logic writes_rd;
    logic illegal;

    logic [11:0] csr_addr;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    logic        csr_we;
    logic        is_csr;
    logic        mret;

    assign csr_addr = instr[31:20];
    assign is_csr   = (opcode == 7'b1110011) && (funct3 != 3'b000);
    assign mret     = (opcode == 7'b1110011) &&
                      (funct3 == 3'b000)     &&
                      (instr[31:20] == 12'h302);

    logic       mem_we, mem_re, mem_to_reg;
    logic [2:0] mem_funct3;
    logic       trap;
    logic [3:0] trap_cause;
    logic [31:0] pc_next;
    logic [31:0] mem_data;
    logic        misaligned;
    logic        branch;
    logic        branch_taken;
    logic [31:0] branch_target;

    assign dbg_mem0 = {dmem_u.mem[3], dmem_u.mem[2], dmem_u.mem[1], dmem_u.mem[0]};
    assign dbg_mem4 = {dmem_u.mem[7], dmem_u.mem[6], dmem_u.mem[5], dmem_u.mem[4]};

    integer cycle = 0;

    function string alu_op_name(input logic [4:0] ctrl);
        case (ctrl)
            5'b00000: alu_op_name = "ADD";
            5'b00001: alu_op_name = "SUB";
            5'b00010: alu_op_name = "AND";
            5'b00011: alu_op_name = "OR";
            5'b00100: alu_op_name = "XOR";
            5'b00101: alu_op_name = "SLL";
            5'b00110: alu_op_name = "SRL";
            5'b00111: alu_op_name = "SRA";
            5'b01000: alu_op_name = "SLT";
            5'b01001: alu_op_name = "SLTU";
            5'b01010: alu_op_name = "BEQ";
            5'b01011: alu_op_name = "BNE";
            5'b01100: alu_op_name = "BGE";
            5'b01101: alu_op_name = "BGT";
            5'b01110: alu_op_name = "MUL";
            5'b01111: alu_op_name = "MULH";
            5'b10000: alu_op_name = "MULHSU";
            5'b10001: alu_op_name = "MULHU";
            5'b10010: alu_op_name = "DIV";
            5'b10011: alu_op_name = "DIVU";
            5'b10100: alu_op_name = "REM";
            5'b10101: alu_op_name = "REMU";
            default:  alu_op_name = "UNKNOWN";
        endcase
    endfunction

    // =========================================================================
    // Multi-cycle stall logic
    // =========================================================================
    //
    // is_muldiv - the current instruction is a MUL/DIV family op
    // muldiv_start - single-cycle pulse to kick off the muldiv_unit
    // muldiv_active - registered flag: unit has been started and not yet finished
    // muldiv_ready - single-cycle pulse from muldiv_unit when result is valid
    // muldiv_result - result from muldiv_unit
    // stall - hold PC and suppress writeback while unit is working
    //
    // Timeline for a DIV instruction (DIV_CYCLES = 8):
    //
    //   Cycle │ is_muldiv │ muldiv_active │ muldiv_ready │ stall │ action
    //   ──────┼───────────┼───────────────┼──────────────┼───────┼───────────
    //     T   │     1     │       0       │      0       │   1   │ start=1, latch operands
    //   T+1…7 │     1     │       1       │      0       │   1   │ counting
    //    T+8  │     1     │       1       │      1       │   0   │ writeback, advance PC
    //    T+9  │     0     │       0       │      0       │   0   │ next instruction
    //
    // =========================================================================

    logic        is_muldiv;
    logic        muldiv_start;
    logic        muldiv_active;
    logic        muldiv_ready;
    logic [31:0] muldiv_result;
    logic        stall;

    // alu_control codes 14 (5'b01110, MUL) through 21 (5'b10101, REMU)
    assign is_muldiv = (alu_control >= 5'b01110);

    // Pulse start only on the first cycle of the instruction
    assign muldiv_start = is_muldiv && !muldiv_active;

    // Track whether the unit is currently busy
    always_ff @(posedge clk) begin
        if (reset)
            muldiv_active <= 1'b0;
        else if (muldiv_ready)
            muldiv_active <= 1'b0;
        else if (muldiv_start)
            muldiv_active <= 1'b1;
    end

    // Stall = waiting for result; clear when result arrives so PC advances
    assign stall = is_muldiv && !muldiv_ready && muldiv_active
                || muldiv_start; // also stall on the launch cycle

    assign dbg_stall = stall;   // expose to testbench

    // =========================================================================

    pc pc_u (
        .clk     (clk),
        .reset   (reset),
        .pc_next (pc_next),
        .pc_out  (pc)
    );

  

    instruction_input_memory imem_u (
        .addr  (pc),
        .instr (instr)
    );

    logic [31:0] if_id_instr;
    logic [31:0] if_id_pc;

    always_ff @(posedge clk) begin 
        if (reset) begin
            if_id_instr <= 0;
            if_id_pc <= 0;
        end
        else begin
            if_id_instr <= instr;
            if_id_pc <= pc;
        end
    end 

    decoder dec_u (
        .instr  (instr),
        .opcode (opcode),
        .rd     (rd),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct3 (funct3),
        .funct7 (funct7),

        .is_r(is_r),
        .is_i(is_i),
        .is_load(is_load),
        .is_store(is_store),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),

        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2),
        .writes_rd(writes_rd),

        .illegal(illegal)

    );

    logic [31:0] imm;

    imm_gen imm_u (
        .instr (instr),
        .imm   (imm)
    );

    branch_unit branch_u (
        .a(rs1_val),
        .b(rs2_val),
        .funct3(funct3),
        .taken(branch_taken_internal)
    );

    logic jal;
    assign jal  = (opcode == 7'b1101111);

    logic jalr;
    assign jalr = (opcode == 7'b1100111);

    assign branch_taken =
        jal || jalr || (branch && branch_taken_internal);

    assign branch_target =
        jal  ? (pc + imm) :
        jalr ? ((rs1_val + imm) & 32'hFFFFFFFE) :
               (pc + imm);

    assign alu_b = (alu_src) ? imm : rs2_val;

    logic [31:0] alu_out;

    control_unit ctrl_u (
        .opcode      (opcode),
        .instr       (instr),
        .funct3      (funct3),
        .reg_we      (reg_we),
        .alu_src     (alu_src),
        .alu_op      (alu_op),
        .mem_we      (mem_we),
        .mem_re      (mem_re),
        .mem_to_reg  (mem_to_reg),
        .mem_funct3  (mem_funct3),
        .branch      (branch),
        .trap        (trap),
        .trap_cause  (trap_cause)
    );


    // bus wires cpu_top -> bus -> dmem/uart

    logic [31:0] bus_rdata;
    logic dmem_we_bus, dmem_re_bus;
    logic [31:0] dmem_addr_bus, dmem_wdata_bus, dmem_rdata_bus;
    logic dmem_misaligned_bus;

    logic uart_cs_bus, uart_we_bus;
    logic [31:0] uart_addr_bus, uart_wdata_bus, uart_rdata_bus;

     
    bus bus_u (
        .clk            (clk),
        .reset          (reset),
        .we             (mem_we),
        .re             (mem_re),
        .addr           (alu_out),
        .wdata          (rs2_val),
        .funct3         (funct3),
        .rdata          (bus_rdata),
        .misaligned     (misaligned),
        // dmem
        .dmem_we        (dmem_we_bus),
        .dmem_re        (dmem_re_bus),
        .dmem_addr      (dmem_addr_bus),
        .dmem_wdata     (dmem_wdata_bus),
        .dmem_rdata     (dmem_rdata_bus),
        .dmem_misaligned(dmem_misaligned_bus),
        // uart
        .uart_cs        (uart_cs_bus),
        .uart_we        (uart_we_bus),
        .uart_addr      (uart_addr_bus),
        .uart_wdata     (uart_wdata_bus),
        .uart_rdata     (uart_rdata_bus)
    );

    dmem dmem_u (
        .clk        (clk),
        .we         (dmem_we_bus),
        .funct3     (funct3),
        .misaligned (dmem_misaligned_bus),
        .addr       (dmem_addr_bus),
        .re         (dmem_re_bus),
        .wd         (dmem_wdata_bus),
        .rd         (dmem_rdata_bus)
    );

    uart uart_u (
        .clk     (clk),
        .reset   (reset),
        .cs      (uart_cs_bus),
        .we      (uart_we_bus),
        .addr    (uart_addr_bus),
        .wdata   (uart_wdata_bus),
        .rdata   (uart_rdata_bus),
        .uart_tx (uart_tx)
    );

    assign mem_data = bus_rdata;

    alu_control_unit alu_ctrl_u (
        .alu_op      (alu_op),
        .funct3      (funct3),
        .funct7      (funct7),
        .alu_control (alu_control)
    );

    // ----- multi-cycle unit -----
    muldiv_unit muldiv_u (
        .clk    (clk),
        .reset  (reset),
        .start  (muldiv_start),
        .a      (alu_a),
        .b      (alu_b),
        .op     (alu_control),
        .result (muldiv_result),
        .ready  (muldiv_ready)
    );
    // ----------------------------

    trap trap_u (
        .trap            (trap),
        .mtvec           (csr_rdata),
        .pc_normal_next  (next_pc),
        .pc_next         (pc_next)
    );

    logic [31:0] alu_a;

    assign alu_a =
        (opcode == 7'b0110111) ? 32'd0 :
        (opcode == 7'b0010111) ? pc     :
                                 rs1_val;

    alu alu_u (
        .a           (alu_a),
        .b           (alu_b),
        .alu_control (alu_control),
        .y           (alu_out)
    );

    logic [31:0] rs1_val, rs2_val;
    logic        reg_we;

    logic [31:0] writeback_data;

    always_comb begin
        csr_we    = 1'b0;
        csr_wdata = 32'd0;

        if (is_csr) begin
            csr_we = 1'b1;
            case (funct3)
                3'b001: csr_wdata = rs1_val;               // CSRRW
                3'b010: csr_wdata = csr_rdata | rs1_val;   // CSRRS
                3'b011: csr_wdata = csr_rdata & ~rs1_val;  // CSRRC
                3'b101: csr_wdata = rs1;                   // CSRRWI
                3'b110: csr_wdata = csr_rdata | rs1;
                3'b111: csr_wdata = csr_rdata & ~rs1;
            endcase
        end
    end

    csr csr_u (
        .clk         (clk),
        .we          (csr_we),
        .csr_addr    (csr_addr),
        .csr_wdata   (csr_wdata),
        .csr_rdata   (csr_rdata),
        .trap_mepc   (pc),
        .trap_mcause ({28'b0, trap_cause}),
        .trap_write  (trap)
    );

    // Writeback mux: muldiv result takes priority over alu_out for M-ext ops
    assign writeback_data =
        (mret)        ? csr_rdata    :
        (is_csr)      ? csr_rdata    :
        (jal || jalr) ? (pc + 32'd4) :
        (mem_to_reg)  ? mem_data     :
        (is_muldiv)   ? muldiv_result :  // <- result from multi-cycle unit
                        alu_out;

    // Suppress register write while stalled or on a trap
    logic reg_we_final;
    assign reg_we_final = (trap || stall) ? 1'b0 : reg_we;

    regfile rf_u (
        .clk    (clk),
        .rs1    (rs1),
        .rs2    (rs2),
        .rd     (rd),
        .wd     (writeback_data),
        .we     (reg_we_final),
        .rd1    (rs1_val),
        .rd2    (rs2_val),
        .dbg_x1 (dbg_x1),
        .dbg_x2 (dbg_x2),
        .dbg_x3 (dbg_x3)
    );

    logic [31:0] next_pc;

    // When stalled: hold PC in place
    assign next_pc =
        stall        ? pc           :
        mret         ? csr_rdata    :
        branch_taken ? branch_target :
                       (pc + 32'd4);

        always_ff @(posedge clk) begin
        if (!reset && uart_cs_bus && uart_we_bus && uart_addr_bus[3:2] == 2'b00) begin
            $write("%c", uart_wdata_bus[7:0]);
        end
    end
 

    always @(posedge clk) begin
        cycle++;
 
        if (misaligned) begin
            $display("[UART/MEM] MISALIGNED ACCESS @ 0x%08h funct3=%03b",
                     alu_out, funct3);
        end
 
        if (trap) begin
            $display("[TRAP] cause=%0d mtvec=0x%08h", trap_cause, csr_rdata);
        end
 
        // UART traffic summary
        if (uart_cs_bus) begin
            if (uart_we_bus)
                $display("[UART WR] addr=0x%08h data=0x%08h ('%c')",
                         uart_addr_bus, uart_wdata_bus,
                         (uart_wdata_bus[7:0] >= 8'h20) ? uart_wdata_bus[7:0] : 8'h3F);
            else
                $display("[UART RD] addr=0x%08h → 0x%08h", uart_addr_bus, uart_rdata_bus);
        end
 
        $display("CYC %0d  PC=0x%08h  INST=0x%08h  OP=%s  RD=x%0d  WB=0x%08h  STALL=%b",
                 cycle, pc, instr, alu_op_name(alu_control),
                 rd, writeback_data, stall);
    end


    function string instr_name();
        case (opcode)
            7'b0110011: instr_name = "R-TYPE";
            7'b0010011: instr_name = "I-TYPE";
            7'b0000011: instr_name = "LOAD";
            7'b0100011: instr_name = "STORE";
            7'b1100011: instr_name = "BRANCH";
            7'b1101111: instr_name = "JAL";
            7'b1100111: instr_name = "JALR";
            7'b0110111: instr_name = "LUI";
            7'b0010111: instr_name = "AUIPC";
            7'b1110011: instr_name = "SYSTEM";
            default:    instr_name = "UNKNOWN";
        endcase
    endfunction

    // =========================================================================
    // Debug display
    // =========================================================================
    always @(posedge clk) begin
        cycle++;

        $display("");
        $display("======================================================================");
        $display("                      CYCLE %0d", cycle);
        $display("======================================================================");

        if (stall) begin
            $display("*** STALL *** (multi-cycle op: %s, active=%b, ready=%b)",
                     alu_op_name(alu_control), muldiv_active, muldiv_ready);
            $display("*** STALL BREAKDOWN ***");
            $display("  is_muldiv      : %b", is_muldiv);
            $display("  muldiv_start   : %b", muldiv_start);
            $display("  muldiv_active  : %b", muldiv_active);
            $display("  muldiv_ready   : %b", muldiv_ready);
        end

        if (is_muldiv) begin
            $display("MULDIV TRACE");
            $display("  start   : %b", muldiv_start);
            $display("  active  : %b", muldiv_active);
            $display("  ready   : %b", muldiv_ready);
            $display("  result  : %0d (0x%08h)", muldiv_result, muldiv_result);
            $display("");
        end

        if (misaligned) begin
            $display("==========================================");
            $display(" MISALIGNED MEMORY ACCESS DETECTED ");
            $display(" funct3  : %03b", funct3);
            $display("==========================================");
        end

        if (trap) begin
            $display("*** TRAP DETECTED ***");
            $display("  cause : %0d", trap_cause);
            $display("  mtvec : 0x%08h", csr_rdata);
        end

        $display("  Instruction Type : %s", instr_name());
        $display("  mem_addr   : 0x%08h", alu_out);

        $display("PC STAGE");
        $display("  PC (hex) : 0x%08h", pc);
        $display("  PC (dec) : %0d", pc);
        $display("  PC (bin) : %032b", pc);
        $display("  IF -> ID PC (hex)  : 0x%08h", if_id_pc);
        $display("  IF -> ID PC (dec)  : %0d", if_id_pc);
        $display("  IF -> ID PC (bin)  : %32b", if_id_pc);
        $display("");

        $display("FETCH STAGE");
        $display("  Instruction (hex) : 0x%08h", instr);
        $display("  IF -> ID Instruction (hex): 0x%08h", if_id_instr);
        $display("  Instruction (bin) : %032b", instr);
        $display("  IF -> ID Instruction (bin): %032b", if_id_instr);
        $display("");

        $display("DECODE STAGE");
        $display("  opcode : %07b (0x%02h)", opcode, opcode);
        $display("  rd     : x%0d", rd);
        $display("  rs1    : x%0d", rs1);
        $display("  rs2    : x%0d", rs2);
        $display("  funct3 : %03b", funct3);
        $display("  funct7 : %07b", funct7);
        $display("");

        $display("DECODE FLAGS");
        $display("  is_r=%b is_i=%b load=%b store=%b branch=%b",
         is_r, is_i, is_load, is_store, is_branch);
        $display("  jal=%b jalr=%b lui=%b auipc=%b",
         is_jal, is_jalr, is_lui, is_auipc);
        $display("  uses_rs1=%b uses_rs2=%b writes_rd=%b illegal=%b",
         uses_rs1, uses_rs2, writes_rd, illegal);
        $display("");

        if (illegal) begin
            $display("!!! ILLEGAL INSTRUCTION DETECTED !!!");
            $display("  instr : 0x%08h", instr);
        end

        $display("CONTROL SIGNALS");
        $display("  reg_we     : %b", reg_we);
        $display("  alu_src    : %b (%s)",
                 alu_src,
                 alu_src ? "Using Immediate" : "Using rs2");
        $display("  alu_op     : %02b", alu_op);
        $display("  alu_ctrl   : %05b (%s)",
                 alu_control, alu_op_name(alu_control));
        $display("  stall      : %b  (is_muldiv=%b muldiv_active=%b muldiv_ready=%b)",
                 stall, is_muldiv, muldiv_active, muldiv_ready);
        $display("");

        $display("REGISTER FILE READ");
        $display("  rs1 (x%0d) value : %0d (0x%08h) (%032b)",
                 rs1, rs1_val, rs1_val, rs1_val);
        $display("  rs2 (x%0d) value : %0d (0x%08h) (%032b)",
                 rs2, rs2_val, rs2_val, rs2_val);
        $display("");

        $display("IMMEDIATE GENERATOR");
        $display("  imm value : %0d (0x%08h) (%032b)", imm, imm, imm);
        $display("");

        $display("ALU EXECUTION");
        $display("  ALU input A : %0d (0x%08h)", alu_a, alu_a);
        $display("  ALU input B : %0d (0x%08h)", alu_b, alu_b);
        $display("  Operation   : %s", alu_op_name(alu_control));
        if (is_muldiv)
            $display("  MulDiv result (when ready) : %0d (0x%08h)",
                     muldiv_result, muldiv_result);
        else
            $display("  ALU result  : %0d (0x%08h) (%032b)",
                     alu_out, alu_out, alu_out);
        $display("");

        $display("WRITEBACK SOURCE SELECT");
        $display("  mret        : %b", mret);
        $display("  is_csr      : %b", is_csr);
        $display("  jal/jalr    : %b", (jal || jalr));
        $display("  mem_to_reg  : %b", mem_to_reg);
        $display("  is_muldiv   : %b", is_muldiv);
        $display("  selected WB : %0d (0x%08h)", writeback_data, writeback_data);
        $display("");

        $display("WRITEBACK STAGE");
        if (reg_we_final && rd != 0)
            $display("  Writing %0d (0x%08h) to register x%0d",
                     writeback_data, writeback_data, rd);
        else if (stall)
            $display("  No write (STALL)");
        else if (trap)
            $display("  No write (TRAP)");
        else if (rd == 0)
            $display("  No register write this cycle (rd=0)");
        else
            $display("  No register write this cycle");
        $display("");

        $display("CONTROL FLOW");
        $display("  jal          : %b", jal);
        $display("  jalr         : %b", jalr);
        $display("  branch       : %b", branch);
        $display("  branch_taken : %b", branch_taken);
        $display("  Branch decision:");
        $display("    condition result : %b", branch_taken_internal);
        $display("    final decision   : %b", branch_taken);
        $display("  branch_target: 0x%08h", branch_target);
        $display("NEXT PC LOGIC");
        if (stall)
            $display("  Reason: STALL (PC held)");
        else if (mret)
            $display("  Reason: MRET -> csr_rdata");
        else if (branch_taken)
            $display("  Reason: BRANCH/JUMP taken");
        else
            $display("  Reason: PC + 4");

        $display("  next_pc : 0x%08h", next_pc);
        $display("");

        $display("BRANCH DETAIL");
        $display("  rs1_val : %0d", rs1_val);
        $display("  rs2_val : %0d", rs2_val);
        $display("  funct3  : %03b", funct3);
        $display("  taken_internal : %b", branch_taken_internal);
        $display("");

        $display("MEMORY STAGE");
        $display("  mem_we     : %b", mem_we);
        $display("  mem_re     : %b", mem_re);
        $display("  mem_to_reg : %b", mem_to_reg);
        $display("  mem_data   : %0d (0x%08h)", mem_data, mem_data);
        $display("MEMORY ACCESS DETAIL");
        $display("  address      : 0x%08h", alu_out);
        $display("  write_data   : %0d (0x%08h)", rs2_val, rs2_val);
        $display("  read_enable  : %b", mem_re);
        $display("  write_enable : %b", mem_we);
        $display("");

        $display("REGISTER SNAPSHOT (before writeback commit)");
        $display("  x1 : %0d", rf_u.regs[1]);
        $display("  x2 : %0d", rf_u.regs[2]);
        $display("  x3 : %0d", rf_u.regs[3]);

        $display("  Next PC     : %0d ", next_pc);
        $display("SUMMARY: PC=0x%08h INST=0x%08h OP=%s RD=x%0d WB=%0d STALL=%b",
         pc, instr, alu_op_name(alu_control), rd, writeback_data, stall);
        $display("======================================================================");
    end

endmodule
