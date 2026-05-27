module cpu_top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] pc_dbg,
    output logic [31:0] dbg_x1,
    output logic [31:0] dbg_mem0,
    output logic [31:0] dbg_mem4,
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3,
    output logic        dbg_stall,
    output logic        uart_tx
);

    /* verilator lint_off WIDTH */
    /* verilator lint_off CASEINCOMPLETE */
    /* verilator lint_off BLKSEQ */

    // instruction decoding fields
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic is_r, is_i, is_load, is_store, is_branch;
    logic is_jal, is_jalr, is_lui, is_auipc;
    logic uses_rs1, uses_rs2, writes_rd;
    logic illegal;

    // program counter fields
    logic [31:0] pc;
    logic [31:0] pc_next;
    assign pc_dbg = pc;

    pc pc_u (
        .clk     (clk),
        .reset   (reset),
        .pc_next (pc_next),
        .pc_out  (pc)
    );

    // instruction "code" memory
    logic [31:0] instr;

    instruction_input_memory imem_u (
        .addr  (pc),
        .instr (instr)
    );

    // IF/ID pipeline registers to be in future
    logic [31:0] if_id_instr;
    logic [31:0] if_id_pc;

    always_ff @(posedge clk) begin
        if (reset) begin
            if_id_instr <= 0;
            if_id_pc    <= 0;
        end else begin
            if_id_instr <= instr;
            if_id_pc    <= pc;
        end
    end

    // decoder
    decoder dec_u (
        .instr     (instr),
        .opcode    (opcode),
        .rd        (rd),
        .rs1       (rs1),
        .rs2       (rs2),
        .funct3    (funct3),
        .funct7    (funct7),
        .is_r      (is_r),
        .is_i      (is_i),
        .is_load   (is_load),
        .is_store  (is_store),
        .is_branch (is_branch),
        .is_jal    (is_jal),
        .is_jalr   (is_jalr),
        .is_lui    (is_lui),
        .is_auipc  (is_auipc),
        .uses_rs1  (uses_rs1),
        .uses_rs2  (uses_rs2),
        .writes_rd (writes_rd),
        .illegal   (illegal)
    );

    // immediate generator
    logic [31:0] imm;

    imm_gen imm_u (
        .instr (instr),
        .imm   (imm)
    );

    // register file
    logic [31:0] rs1_val, rs2_val;
    logic        reg_we;
    logic        reg_we_final;
    logic [31:0] writeback_data;

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

    // csr signals
    logic [11:0] csr_addr;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    logic        csr_we;
    logic        is_csr;
    logic        mret;
    logic        mstatus_mie;   // global interrupt enable

    assign csr_addr = instr[31:20];
    assign is_csr   = (opcode == 7'b1110011) && (funct3 != 3'b000);
    assign mret     = (opcode == 7'b1110011) &&
                      (funct3 == 3'b000)     &&
                      (instr[31:20] == 12'h302);

    always_comb begin
        csr_we    = 1'b0;
        csr_wdata = 32'd0;
        if (is_csr) begin
            csr_we = 1'b1;
            case (funct3)
                3'b001: csr_wdata = rs1_val;
                3'b010: csr_wdata = csr_rdata | rs1_val;
                3'b011: csr_wdata = csr_rdata & ~rs1_val;
                3'b101: csr_wdata = {27'b0, rs1};
                3'b110: csr_wdata = csr_rdata | {27'b0, rs1};
                3'b111: csr_wdata = csr_rdata & ~{27'b0, rs1};
                default: csr_wdata = 32'd0;
            endcase
        end
    end

    // plic initiation
    logic        irq_pending;  

    logic        plic_cs_bus, plic_we_bus;
    logic [31:0] plic_addr_bus, plic_wdata_bus, plic_rdata_bus;

    logic [2:0] irq_src;
    assign irq_src = 3'b000;   // wire peripherals here

    plic plic_u (
        .clk        (clk),
        .reset      (reset),
        .irq_src    (irq_src),
        .cs         (plic_cs_bus),
        .we         (plic_we_bus),
        .addr       (plic_addr_bus),
        .wdata      (plic_wdata_bus),
        .rdata      (plic_rdata_bus),
        .irq_pending(irq_pending)
    );

    // csr module
    logic [31:0] mip_hw;
    assign mip_hw = {20'b0, irq_pending, 11'b0};  

    logic        csr_trap_write;   
    logic [31:0] mtvec_out;       
    logic [31:0] mcause_out;       

    csr csr_u (
        .clk         (clk),
        .reset       (reset),
        .we          (csr_we),
        .csr_addr    (csr_addr),
        .csr_wdata   (csr_wdata),
        .csr_rdata   (csr_rdata),
        .mstatus_mie (mstatus_mie),
        .trap_mepc   (pc),
        .trap_mcause (mcause_out),
        .trap_write  (csr_trap_write),
        .mip_hw      (mip_hw),
        .mtvec_out   (mtvec_out)
    );

    // control unit
    logic        mem_we, mem_re, mem_to_reg;
    logic [2:0]  mem_funct3;
    logic        branch;
    logic        sync_trap;        // synchronous trap from opcode decode
    logic [3:0]  trap_cause;

    control_unit ctrl_u (
        .opcode      (opcode),
        .instr       (instr),
        .funct3      (funct3),
        .irq_pending (irq_pending),
        .mstatus_mie (mstatus_mie),
        .reg_we      (reg_we),
        .alu_src     (alu_src),
        .alu_op      (alu_op),
        .mem_we      (mem_we),
        .mem_re      (mem_re),
        .mem_to_reg  (mem_to_reg),
        .mem_funct3  (mem_funct3),
        .branch      (branch),
        .trap        (sync_trap),
        .trap_cause  (trap_cause)
    );

    // alu control unit
    logic        alu_src;
    logic [1:0]  alu_op;
    logic [4:0]  alu_control;
    logic [31:0] alu_b;

    alu_control_unit alu_ctrl_u (
        .alu_op      (alu_op),
        .funct3      (funct3),
        .funct7      (funct7),
        .alu_control (alu_control)
    );

    // mul/div logic (this one is multi cycled)
    logic        is_muldiv;
    logic        muldiv_start;
    logic        muldiv_active;
    logic        muldiv_ready;
    logic [31:0] muldiv_result;
    logic        stall;
    logic [31:0] alu_a;

    assign is_muldiv    = (alu_control >= 5'b01110);
    assign muldiv_start = is_muldiv && !muldiv_active;

    always_ff @(posedge clk) begin
        if (reset)
            muldiv_active <= 1'b0;
        else if (muldiv_ready)
            muldiv_active <= 1'b0;
        else if (muldiv_start)
            muldiv_active <= 1'b1;
    end

    assign stall     = (is_muldiv && !muldiv_ready && muldiv_active) || muldiv_start;
    assign dbg_stall = stall;

    // alu operation unit
    logic [31:0] alu_out;

    assign alu_a = (opcode == 7'b0110111) ? 32'd0 :
                   (opcode == 7'b0010111) ? pc     :
                                            rs1_val;

    assign alu_b = alu_src ? imm : rs2_val;

    alu alu_u (
        .a           (alu_a),
        .b           (alu_b),
        .alu_control (alu_control),
        .y           (alu_out)
    );

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

    // branch and jump
    logic        branch_taken_internal;
    logic        branch_taken;
    logic [31:0] branch_target;

    logic jal, jalr;
    assign jal  = (opcode == 7'b1101111);
    assign jalr = (opcode == 7'b1100111);

    branch_unit branch_u (
        .a      (rs1_val),
        .b      (rs2_val),
        .funct3 (funct3),
        .taken  (branch_taken_internal)
    );

    assign branch_taken  = jal || jalr || (branch && branch_taken_internal);
    assign branch_target = jal  ? (pc + imm) :
                           jalr ? ((rs1_val + imm) & 32'hFFFFFFFE) :
                                  (pc + imm);

   // bus and memory
    logic [31:0] bus_rdata;
    logic        misaligned;

    logic        dmem_we_bus, dmem_re_bus;
    logic [31:0] dmem_addr_bus, dmem_wdata_bus, dmem_rdata_bus;
    logic        dmem_misaligned_bus;

    logic        uart_cs_bus, uart_we_bus;
    logic [31:0] uart_addr_bus, uart_wdata_bus, uart_rdata_bus;

    bus bus_u (
        .clk             (clk),
        .reset           (reset),
        .we              (mem_we),
        .re              (mem_re),
        .addr            (alu_out),
        .wdata           (rs2_val),
        .funct3          (funct3),
        .rdata           (bus_rdata),
        .misaligned      (misaligned),
        // dmem
        .dmem_we         (dmem_we_bus),
        .dmem_re         (dmem_re_bus),
        .dmem_addr       (dmem_addr_bus),
        .dmem_wdata      (dmem_wdata_bus),
        .dmem_rdata      (dmem_rdata_bus),
        .dmem_misaligned (dmem_misaligned_bus),
        // uart
        .uart_cs         (uart_cs_bus),
        .uart_we         (uart_we_bus),
        .uart_addr       (uart_addr_bus),
        .uart_wdata      (uart_wdata_bus),
        .uart_rdata      (uart_rdata_bus),
        // plic
        .plic_cs         (plic_cs_bus),
        .plic_we         (plic_we_bus),
        .plic_addr       (plic_addr_bus),
        .plic_wdata      (plic_wdata_bus),
        .plic_rdata      (plic_rdata_bus)
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

    assign dbg_mem0 = {dmem_u.mem[3], dmem_u.mem[2], dmem_u.mem[1], dmem_u.mem[0]};
    assign dbg_mem4 = {dmem_u.mem[7], dmem_u.mem[6], dmem_u.mem[5], dmem_u.mem[4]};

    logic [31:0] mem_data;
    assign mem_data = bus_rdata;

    logic irq;
    assign irq = irq_pending && mstatus_mie && !stall && !sync_trap;


    logic        take_trap;
    logic [31:0] next_pc_normal;

    // normal next-PC before trap override
    assign next_pc_normal = stall        ? pc            :
                            mret         ? csr_rdata     :
                            branch_taken ? branch_target :
                                           (pc + 32'd4);

    trap trap_u (
        .trap           (sync_trap),
        .trap_cause     (trap_cause),
        .irq            (irq),
        .mtvec          (mtvec_out),
        .mepc_in        (pc),
        .pc_next        (pc_next),
        .pc_normal_next (next_pc_normal),
        .take_trap      (take_trap),
        .mcause_out     (mcause_out),
        .csr_trap_write (csr_trap_write)
    );

    // writeback multiplexer
    assign writeback_data =
        mret         ? csr_rdata    :
        is_csr       ? csr_rdata    :
        (jal||jalr)  ? (pc + 32'd4) :
        mem_to_reg   ? mem_data     :
        is_muldiv    ? muldiv_result :
                       alu_out;

    assign reg_we_final = (take_trap || stall) ? 1'b0 : reg_we;


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

    integer cycle = 0;

    // UART simulation
    always_ff @(posedge clk) begin
        if (!reset && uart_cs_bus && uart_we_bus && uart_addr_bus[3:2] == 2'b00)
            $write("%c", uart_wdata_bus[7:0]);
    end

    always @(posedge clk) begin
        cycle++;

        if (uart_cs_bus) begin
            if (uart_we_bus)
                $display("[UART WR] addr=0x%08h data=0x%08h ('%c')",
                         uart_addr_bus, uart_wdata_bus,
                         (uart_wdata_bus[7:0] >= 8'h20) ? uart_wdata_bus[7:0] : 8'h3F);
            else
                $display("[UART RD] addr=0x%08h → 0x%08h", uart_addr_bus, uart_rdata_bus);
        end

        $display("CYC %0d  PC=0x%08h  INST=0x%08h  OP=%s  RD=x%0d  WB=0x%08h  STALL=%b  IRQ=%b  TRAP=%b",
                 cycle, pc, instr, alu_op_name(alu_control),
                 rd, writeback_data, stall, irq, take_trap);
    end

    always @(posedge clk) begin
        $display("");
        $display("======================================================================");
        $display("                      CYCLE %0d", cycle);
        $display("======================================================================");

        if (stall) begin
            $display("*** STALL *** (multi-cycle op: %s, active=%b, ready=%b)",
                     alu_op_name(alu_control), muldiv_active, muldiv_ready);
        end

        if (irq)
            $display("*** HARDWARE INTERRUPT *** (irq_pending=%b mstatus_mie=%b)",
                     irq_pending, mstatus_mie);

        if (take_trap && !irq)
            $display("*** SYNC TRAP *** cause=%0d", trap_cause);

        $display("  Instruction Type : %s", instr_name());

        $display("PC STAGE");
        $display("  PC       : 0x%08h", pc);
        $display("  next_pc  : 0x%08h", pc_next);

        $display("DECODE STAGE");
        $display("  opcode : %07b  rd=x%0d  rs1=x%0d  rs2=x%0d  funct3=%03b  funct7=%07b",
                 opcode, rd, rs1, rs2, funct3, funct7);

        $display("INTERRUPT / TRAP");
        $display("  irq_pending  : %b", irq_pending);
        $display("  mstatus_mie  : %b", mstatus_mie);
        $display("  irq (gated)  : %b", irq);
        $display("  sync_trap    : %b  cause=%0d", sync_trap, trap_cause);
        $display("  take_trap    : %b", take_trap);
        $display("  mcause_out   : 0x%08h", mcause_out);

        $display("CONTROL SIGNALS");
        $display("  reg_we=%b  alu_src=%b  alu_op=%02b  alu_ctrl=%05b (%s)",
                 reg_we, alu_src, alu_op, alu_control, alu_op_name(alu_control));

        $display("ALU");
        $display("  A=0x%08h  B=0x%08h  result=0x%08h", alu_a, alu_b, alu_out);

        $display("WRITEBACK");
        if (reg_we_final && rd != 0)
            $display("  Writing 0x%08h -> x%0d", writeback_data, rd);
        else if (stall)
            $display("  No write (STALL)");
        else if (take_trap)
            $display("  No write (TRAP/IRQ)");
        else
            $display("  No write this cycle");

        $display("REGISTER SNAPSHOT");
        $display("  x1=%0d  x2=%0d  x3=%0d", rf_u.regs[1], rf_u.regs[2], rf_u.regs[3]);

        $display("======================================================================");
    end

endmodule