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
    output logic        uart_tx,
    output logic [31:0] dbg_x14,
    output logic [31:0] dbg_x15
);

    /* verilator lint_off WIDTH */
    /* verilator lint_off CASEINCOMPLETE */
    /* verilator lint_off BLKSEQ */

    // IF stage

    logic [31:0] pc;
    logic [31:0] pc_next;
    assign pc_dbg = pc;

    pc pc_u (
        .clk     (clk),
        .reset   (reset),
        .pc_next (pc_next),
        .pc_out  (pc)
    );

    logic [31:0] if_instr;

    instruction_input_memory imem_u (
        .addr  (pc),
        .instr (if_instr)
    );

    // IF -> ID register

    logic [31:0] if_id_instr;
    logic [31:0] if_id_pc;

    always_ff @(posedge clk) begin
        if (reset || if_id_flush_w || branch_flush) begin
            if_id_instr <= 32'h00000013;
            if_id_pc    <= 32'd0;
        end else if (!stall_w && !ex_muldiv_stall) begin
            if_id_instr <= if_instr;
            if_id_pc    <= pc;
        end
    end

    // ID stage

    logic [6:0]  id_opcode;
    logic [4:0]  id_rd, id_rs1, id_rs2;
    logic [2:0]  id_funct3;
    logic [6:0]  id_funct7;
    logic        id_is_r, id_is_i, id_is_load, id_is_store, id_is_branch;
    logic        id_is_jal, id_is_jalr, id_is_lui, id_is_auipc;
    logic        id_uses_rs1, id_uses_rs2, id_writes_rd, id_illegal;

    decoder dec_u (
        .instr     (if_id_instr),
        .opcode    (id_opcode),
        .rd        (id_rd),
        .rs1       (id_rs1),
        .rs2       (id_rs2),
        .funct3    (id_funct3),
        .funct7    (id_funct7),
        .is_r      (id_is_r),
        .is_i      (id_is_i),
        .is_load   (id_is_load),
        .is_store  (id_is_store),
        .is_branch (id_is_branch),
        .is_jal    (id_is_jal),
        .is_jalr   (id_is_jalr),
        .is_lui    (id_is_lui),
        .is_auipc  (id_is_auipc),
        .uses_rs1  (id_uses_rs1),
        .uses_rs2  (id_uses_rs2),
        .writes_rd (id_writes_rd),
        .illegal   (id_illegal)
    );

    logic [31:0] id_imm;

    imm_gen imm_u (
        .instr (if_id_instr),
        .imm   (id_imm)
    );

    logic        id_reg_we, id_alu_src;
    logic [1:0]  id_alu_op;
    logic        id_mem_we, id_mem_re, id_mem_to_reg;
    logic [2:0]  id_mem_funct3;
    logic        id_branch;
    logic        id_sync_trap;
    logic [3:0]  id_trap_cause;

    control_unit ctrl_u (
        .opcode      (id_opcode),
        .instr       (if_id_instr),
        .funct3      (id_funct3),
        .irq_pending (irq_pending),
        .mstatus_mie (mstatus_mie),
        .reg_we      (id_reg_we),
        .alu_src     (id_alu_src),
        .alu_op      (id_alu_op),
        .mem_we      (id_mem_we),
        .mem_re      (id_mem_re),
        .mem_to_reg  (id_mem_to_reg),
        .mem_funct3  (id_mem_funct3),
        .branch      (id_branch),
        .trap        (id_sync_trap),
        .trap_cause  (id_trap_cause)
    );

    logic [31:0] id_rs1_val, id_rs2_val;

    regfile rf_u (
        .clk    (clk),
        .rs1    (id_rs1),
        .rs2    (id_rs2),
        .rd     (wb_rd),
        .wd     (wb_data),
        .we     (wb_reg_we),
        .rd1    (id_rs1_val),
        .rd2    (id_rs2_val),
        .dbg_x1 (dbg_x1),
        .dbg_x2 (dbg_x2),
        .dbg_x3 (dbg_x3),
        .dbg_x14 (dbg_x14),
        .dbg_x15 (dbg_x15)
    );

    logic [11:0] id_csr_addr;
    logic        id_is_csr;
    logic        id_mret;

    assign id_csr_addr = if_id_instr[31:20];
    assign id_is_csr   = (id_opcode == 7'b1110011) && (id_funct3 != 3'b000);
    assign id_mret     = (id_opcode == 7'b1110011) &&
                         (id_funct3 == 3'b000)     &&
                         (if_id_instr[31:20] == 12'h302);

    // ID -> EX registers

    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_instr;
    logic [6:0]  id_ex_opcode;
    logic [4:0]  id_ex_rd, id_ex_rs1, id_ex_rs2;
    logic [2:0]  id_ex_funct3;
    logic [6:0]  id_ex_funct7;
    logic [31:0] id_ex_rs1_val, id_ex_rs2_val;
    logic [31:0] id_ex_imm;
    logic        id_ex_reg_we, id_ex_alu_src;
    logic [1:0]  id_ex_alu_op;
    logic        id_ex_mem_we, id_ex_mem_re, id_ex_mem_to_reg;
    logic [2:0]  id_ex_mem_funct3;
    logic        id_ex_branch;
    logic        id_ex_sync_trap;
    logic [3:0]  id_ex_trap_cause;
    logic        id_ex_is_csr;
    logic        id_ex_mret;
    logic [11:0] id_ex_csr_addr;
    logic        id_ex_is_jal, id_ex_is_jalr;

    always_ff @(posedge clk) begin
        if (reset || id_ex_flush_w || branch_flush) begin
            id_ex_pc          <= 32'd0;
            id_ex_instr       <= 32'h00000013;
            id_ex_opcode      <= 7'd0;
            id_ex_rd          <= 5'd0;
            id_ex_rs1         <= 5'd0;
            id_ex_rs2         <= 5'd0;
            id_ex_funct3      <= 3'd0;
            id_ex_funct7      <= 7'd0;
            id_ex_rs1_val     <= 32'd0;
            id_ex_rs2_val     <= 32'd0;
            id_ex_imm         <= 32'd0;
            id_ex_reg_we      <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_alu_op      <= 2'd0;
            id_ex_mem_we      <= 1'b0;
            id_ex_mem_re      <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_mem_funct3  <= 3'd0;
            id_ex_branch      <= 1'b0;
            id_ex_sync_trap   <= 1'b0;
            id_ex_trap_cause  <= 4'd0;
            id_ex_is_csr      <= 1'b0;
            id_ex_mret        <= 1'b0;
            id_ex_csr_addr    <= 12'd0;
            id_ex_is_jal      <= 1'b0;
            id_ex_is_jalr     <= 1'b0;
        end else if (!stall_w && !ex_muldiv_stall) begin
            id_ex_pc          <= if_id_pc;
            id_ex_instr       <= if_id_instr;
            id_ex_opcode      <= id_opcode;
            id_ex_rd          <= id_rd;
            id_ex_rs1         <= id_rs1;
            id_ex_rs2         <= id_rs2;
            id_ex_funct3      <= id_funct3;
            id_ex_funct7      <= id_funct7;
            id_ex_rs1_val     <= id_rs1_val;
            id_ex_rs2_val     <= id_rs2_val;
            id_ex_imm         <= id_imm;
            id_ex_reg_we      <= id_reg_we;
            id_ex_alu_src     <= id_alu_src;
            id_ex_alu_op      <= id_alu_op;
            id_ex_mem_we      <= id_mem_we;
            id_ex_mem_re      <= id_mem_re;
            id_ex_mem_to_reg  <= id_mem_to_reg;
            id_ex_mem_funct3  <= id_mem_funct3;
            id_ex_branch      <= id_branch;
            id_ex_sync_trap   <= id_sync_trap;
            id_ex_trap_cause  <= id_trap_cause;
            id_ex_is_csr      <= id_is_csr;
            id_ex_mret        <= id_mret;
            id_ex_csr_addr    <= id_csr_addr;
            id_ex_is_jal      <= id_is_jal;
            id_ex_is_jalr     <= id_is_jalr;
        end
    end

    // EX stage

    logic [4:0]  ex_alu_control;

    alu_control_unit alu_ctrl_u (
        .alu_op      (id_ex_alu_op),
        .funct3      (id_ex_funct3),
        .funct7      (id_ex_funct7),
        .alu_control (ex_alu_control)
    );

    logic [1:0]  forward_a, forward_b;
    logic [31:0] ex_fwd_rs1, ex_fwd_rs2;

always_comb begin
    case (forward_a)
        2'b10:   ex_fwd_rs1 = ex_mem_is_muldiv ? ex_mem_muldiv_result : ex_mem_alu_out;
        2'b01:   ex_fwd_rs1 = wb_data;
        default: ex_fwd_rs1 = id_ex_rs1_val;
    endcase

    case (forward_b)
        2'b10:   ex_fwd_rs2 = ex_mem_is_muldiv ? ex_mem_muldiv_result : ex_mem_alu_out;
        2'b01:   ex_fwd_rs2 = wb_data;
        default: ex_fwd_rs2 = id_ex_rs2_val;
    endcase
end

    logic [31:0] ex_alu_a, ex_alu_b;

    assign ex_alu_a = (id_ex_opcode == 7'b0110111) ? 32'd0        :
                      (id_ex_opcode == 7'b0010111) ? id_ex_pc     :
                                                     ex_fwd_rs1;

    assign ex_alu_b = id_ex_alu_src ? id_ex_imm : ex_fwd_rs2;

    logic [31:0] ex_alu_out;

    alu alu_u (
        .a           (ex_alu_a),
        .b           (ex_alu_b),
        .alu_control (ex_alu_control),
        .y           (ex_alu_out)
    );

    logic        ex_is_muldiv;
    logic        ex_muldiv_start;
    logic        ex_muldiv_active;
    logic        ex_muldiv_ready;
    logic [31:0] ex_muldiv_result;

    assign ex_is_muldiv    = (ex_alu_control >= 5'b01110);
    assign ex_muldiv_start = ex_is_muldiv && !ex_muldiv_active;

    always_ff @(posedge clk) begin
        if (reset)
            ex_muldiv_active <= 1'b0;
        else if (ex_muldiv_ready)
            ex_muldiv_active <= 1'b0;
        else if (ex_muldiv_start)
            ex_muldiv_active <= 1'b1;
    end

    muldiv_unit muldiv_u (
        .clk    (clk),
        .reset  (reset),
        .start  (ex_muldiv_start),
        .a      (ex_alu_a),
        .b      (ex_alu_b),
        .op     (ex_alu_control),
        .result (ex_muldiv_result),
        .ready  (ex_muldiv_ready)
    );

    logic        ex_muldiv_stall;
    assign ex_muldiv_stall = (ex_is_muldiv && !ex_muldiv_ready && ex_muldiv_active)
                           || ex_muldiv_start;

    assign dbg_stall = ex_muldiv_stall;

    logic        ex_branch_taken_internal;
    logic        ex_branch_taken;
    logic [31:0] ex_branch_target;

    branch_unit branch_u (
        .a      (ex_fwd_rs1),
        .b      (ex_fwd_rs2),
        .funct3 (id_ex_funct3),
        .taken  (ex_branch_taken_internal)
    );

    assign ex_branch_taken  = id_ex_is_jal || id_ex_is_jalr ||
                              (id_ex_branch && ex_branch_taken_internal);

    assign ex_branch_target = id_ex_is_jal  ? (id_ex_pc + id_ex_imm) :
                              id_ex_is_jalr ? ((ex_fwd_rs1 + id_ex_imm) & 32'hFFFFFFFE) :
                                              (id_ex_pc + id_ex_imm);

    logic [31:0] ex_csr_rdata;
    logic [31:0] ex_csr_wdata;
    assign ex_csr_rdata = mem_csr_rdata;
    logic        ex_csr_we;

    assign ex_csr_we = id_ex_is_csr;

    always_comb begin
        ex_csr_wdata = 32'd0;
        if (id_ex_is_csr) begin
            case (id_ex_funct3)
                3'b001: ex_csr_wdata = ex_fwd_rs1;
                3'b010: ex_csr_wdata = ex_csr_rdata | ex_fwd_rs1;
                3'b011: ex_csr_wdata = ex_csr_rdata & ~ex_fwd_rs1;
                3'b101: ex_csr_wdata = {27'b0, id_ex_rs1};
                3'b110: ex_csr_wdata = ex_csr_rdata | {27'b0, id_ex_rs1};
                3'b111: ex_csr_wdata = ex_csr_rdata & ~{27'b0, id_ex_rs1};
                default: ex_csr_wdata = 32'd0;
            endcase
        end
    end

    // EX -> MEM registers

    logic [31:0] ex_mem_pc;
    logic [4:0]  ex_mem_rd;
    logic [4:0]  ex_mem_rs2;
    logic [31:0] ex_mem_alu_out;
    logic [31:0] ex_mem_fwd_rs2;
    logic        ex_mem_reg_we;
    logic        ex_mem_mem_we, ex_mem_mem_re, ex_mem_mem_to_reg;
    logic [2:0]  ex_mem_mem_funct3;
    logic        ex_mem_sync_trap;
    logic [3:0]  ex_mem_trap_cause;
    logic        ex_mem_is_csr;
    logic        ex_mem_mret;
    logic [11:0] ex_mem_csr_addr;
    logic [31:0] ex_mem_csr_wdata;
    logic        ex_mem_is_jal, ex_mem_is_jalr;
    logic        ex_mem_is_muldiv;
    logic [31:0] ex_mem_muldiv_result;
    logic        ex_mem_branch_taken;
    logic [31:0] ex_mem_branch_target;

    always_ff @(posedge clk) begin
        if (reset) begin
            ex_mem_pc             <= 32'd0;
            ex_mem_rd             <= 5'd0;
            ex_mem_rs2            <= 5'd0;
            ex_mem_alu_out        <= 32'd0;
            ex_mem_fwd_rs2        <= 32'd0;
            ex_mem_reg_we         <= 1'b0;
            ex_mem_mem_we         <= 1'b0;
            ex_mem_mem_re         <= 1'b0;
            ex_mem_mem_to_reg     <= 1'b0;
            ex_mem_mem_funct3     <= 3'd0;
            ex_mem_sync_trap      <= 1'b0;
            ex_mem_trap_cause     <= 4'd0;
            ex_mem_is_csr         <= 1'b0;
            ex_mem_mret           <= 1'b0;
            ex_mem_csr_addr       <= 12'd0;
            ex_mem_csr_wdata      <= 32'd0;
            ex_mem_is_jal         <= 1'b0;
            ex_mem_is_jalr        <= 1'b0;
            ex_mem_is_muldiv      <= 1'b0;
            ex_mem_muldiv_result  <= 32'd0;
            ex_mem_branch_taken   <= 1'b0;
            ex_mem_branch_target  <= 32'd0;
        end else if (!ex_muldiv_stall) begin
            ex_mem_pc             <= id_ex_pc;
            ex_mem_rd             <= id_ex_rd;
            ex_mem_rs2            <= id_ex_rs2;
            ex_mem_alu_out        <= ex_alu_out;
            ex_mem_fwd_rs2        <= ex_fwd_rs2;
            ex_mem_reg_we         <= id_ex_reg_we;
            ex_mem_mem_we         <= id_ex_mem_we;
            ex_mem_mem_re         <= id_ex_mem_re;
            ex_mem_mem_to_reg     <= id_ex_mem_to_reg;
            ex_mem_mem_funct3     <= id_ex_mem_funct3;
            ex_mem_sync_trap      <= id_ex_sync_trap;
            ex_mem_trap_cause     <= id_ex_trap_cause;
            ex_mem_is_csr         <= id_ex_is_csr;
            ex_mem_mret           <= id_ex_mret;
            ex_mem_csr_addr       <= id_ex_csr_addr;
            ex_mem_csr_wdata      <= ex_csr_wdata;
            ex_mem_is_jal         <= id_ex_is_jal;
            ex_mem_is_jalr        <= id_ex_is_jalr;
            ex_mem_is_muldiv      <= ex_is_muldiv;
            ex_mem_muldiv_result  <= ex_muldiv_result;
            ex_mem_branch_taken   <= ex_branch_taken;
            ex_mem_branch_target  <= ex_branch_target;
        end
    end

    // MEM stage

    logic [31:0] mem_bus_rdata;
    logic        mem_misaligned;

    logic        dmem_we_bus, dmem_re_bus;
    logic [31:0] dmem_addr_bus, dmem_wdata_bus, dmem_rdata_bus;
    logic        dmem_misaligned_bus;

    logic        uart_cs_bus, uart_we_bus;
    logic [31:0] uart_addr_bus, uart_wdata_bus, uart_rdata_bus;

    logic        plic_cs_bus, plic_we_bus;
    logic [31:0] plic_addr_bus, plic_wdata_bus, plic_rdata_bus;

    bus bus_u (
        .clk             (clk),
        .reset           (reset),
        .we              (ex_mem_mem_we),
        .re              (ex_mem_mem_re),
        .addr            (ex_mem_alu_out),
        .wdata           (ex_mem_fwd_rs2),
        .funct3          (ex_mem_mem_funct3),
        .rdata           (mem_bus_rdata),
        .misaligned      (mem_misaligned),
        .dmem_we         (dmem_we_bus),
        .dmem_re         (dmem_re_bus),
        .dmem_addr       (dmem_addr_bus),
        .dmem_wdata      (dmem_wdata_bus),
        .dmem_rdata      (dmem_rdata_bus),
        .dmem_misaligned (dmem_misaligned_bus),
        .uart_cs         (uart_cs_bus),
        .uart_we         (uart_we_bus),
        .uart_addr       (uart_addr_bus),
        .uart_wdata      (uart_wdata_bus),
        .uart_rdata      (uart_rdata_bus),
        .plic_cs         (plic_cs_bus),
        .plic_we         (plic_we_bus),
        .plic_addr       (plic_addr_bus),
        .plic_wdata      (plic_wdata_bus),
        .plic_rdata      (plic_rdata_bus)
    );

    dmem dmem_u (
        .clk        (clk),
        .we         (dmem_we_bus),
        .funct3     (ex_mem_mem_funct3),
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

    logic [31:0] mem_csr_rdata;
    logic        mem_csr_we;

    assign mem_csr_we = ex_mem_is_csr;

    csr csr_u (
        .clk         (clk),
        .reset       (reset),
        .we          (mem_csr_we),
        .csr_addr    (ex_mem_csr_addr),
        .csr_wdata   (ex_mem_csr_wdata),
        .csr_rdata   (mem_csr_rdata),
        .mstatus_mie (mstatus_mie),
        .trap_mepc   (ex_mem_pc),
        .trap_mcause (mem_mcause_out),
        .trap_write  (mem_csr_trap_write),
        .mip_hw      (mip_hw),
        .mtvec_out   (mtvec_out)
    );

    logic [31:0] irq_pending_logic;
    logic        irq_pending;
    logic        mstatus_mie;
    logic [31:0] mip_hw;
    logic [31:0] mtvec_out;
    logic        mem_csr_trap_write;
    logic [31:0] mem_mcause_out;
    logic        mem_take_trap;
    logic        mem_irq;

    assign mip_hw      = {20'b0, irq_pending, 11'b0};
    assign mem_irq     = irq_pending && mstatus_mie && !ex_muldiv_stall && !ex_mem_sync_trap;

    logic [2:0]  irq_src;
    assign irq_src = 3'b000;

    plic plic_u (
        .clk         (clk),
        .reset       (reset),
        .irq_src     (irq_src),
        .cs          (plic_cs_bus),
        .we          (plic_we_bus),
        .addr        (plic_addr_bus),
        .wdata       (plic_wdata_bus),
        .rdata       (plic_rdata_bus),
        .irq_pending (irq_pending)
    );

    logic [31:0] mem_next_pc_normal;

    assign mem_next_pc_normal = ex_mem_mret         ? mem_csr_rdata    :
                                ex_mem_branch_taken  ? ex_mem_branch_target :
                                                       (ex_mem_pc + 32'd4);

    trap trap_u (
        .trap           (ex_mem_sync_trap),
        .trap_cause     (ex_mem_trap_cause),
        .irq            (mem_irq),
        .mtvec          (mtvec_out),
        .mepc_in        (ex_mem_pc),
        .pc_next        (mem_pc_redirect),
        .pc_normal_next (mem_next_pc_normal),
        .take_trap      (mem_take_trap),
        .mcause_out     (mem_mcause_out),
        .csr_trap_write (mem_csr_trap_write)
    );

    logic [31:0] mem_pc_redirect;

    // MEM -> WB registers

    logic [4:0]  mem_wb_rd;
    logic [31:0] mem_wb_alu_out;
    logic [31:0] mem_wb_mem_data;
    logic        mem_wb_reg_we;
    logic        mem_wb_mem_to_reg;
    logic        mem_wb_is_csr;
    logic        mem_wb_mret;
    logic [31:0] mem_wb_csr_rdata;
    logic        mem_wb_is_jal, mem_wb_is_jalr;
    logic [31:0] mem_wb_pc;
    logic        mem_wb_is_muldiv;
    logic [31:0] mem_wb_muldiv_result;
    logic        mem_wb_take_trap;

    always_ff @(posedge clk) begin
        if (reset) begin
            mem_wb_rd            <= 5'd0;
            mem_wb_alu_out       <= 32'd0;
            mem_wb_mem_data      <= 32'd0;
            mem_wb_reg_we        <= 1'b0;
            mem_wb_mem_to_reg    <= 1'b0;
            mem_wb_is_csr        <= 1'b0;
            mem_wb_mret          <= 1'b0;
            mem_wb_csr_rdata     <= 32'd0;
            mem_wb_is_jal        <= 1'b0;
            mem_wb_is_jalr       <= 1'b0;
            mem_wb_pc            <= 32'd0;
            mem_wb_is_muldiv     <= 1'b0;
            mem_wb_muldiv_result <= 32'd0;
            mem_wb_take_trap     <= 1'b0;
        end else begin
            mem_wb_rd            <= ex_mem_rd;
            mem_wb_alu_out       <= ex_mem_alu_out;
            mem_wb_mem_data      <= mem_bus_rdata;
            mem_wb_reg_we        <= ex_mem_reg_we && !mem_take_trap;
            mem_wb_mem_to_reg    <= ex_mem_mem_to_reg;
            mem_wb_is_csr        <= ex_mem_is_csr;
            mem_wb_mret          <= ex_mem_mret;
            mem_wb_csr_rdata     <= mem_csr_rdata;
            mem_wb_is_jal        <= ex_mem_is_jal;
            mem_wb_is_jalr       <= ex_mem_is_jalr;
            mem_wb_pc            <= ex_mem_pc;
            mem_wb_is_muldiv     <= ex_mem_is_muldiv;
            mem_wb_muldiv_result <= ex_mem_muldiv_result;
            mem_wb_take_trap     <= mem_take_trap;
        end
    end

    // WB stage

    logic [31:0] wb_data;
    logic [4:0]  wb_rd;
    logic        wb_reg_we;

    assign wb_rd     = mem_wb_rd;
    assign wb_reg_we = mem_wb_reg_we;

    assign wb_data =
        mem_wb_mret                       ? mem_wb_csr_rdata     :
        mem_wb_is_csr                     ? mem_wb_csr_rdata     :
        (mem_wb_is_jal || mem_wb_is_jalr) ? (mem_wb_pc + 32'd4) :
        mem_wb_mem_to_reg                 ? mem_wb_mem_data      :
        mem_wb_is_muldiv                  ? mem_wb_muldiv_result :
                                            mem_wb_alu_out;

    // next PC selection

    logic        stall_w;
    logic        if_id_flush_w;
    logic        id_ex_flush_w;
    logic        branch_flush;

    hazard_unit hazard_u (
        .id_ex_mem_re    (id_ex_mem_re),
        .id_ex_rd        (id_ex_rd),
        .if_id_rs1       (id_rs1),
        .if_id_rs2       (id_rs2),
        .ex_mem_rd       (ex_mem_rd),
        .ex_mem_reg_we   (ex_mem_reg_we),
        .ex_mem_alu_out  (ex_mem_alu_out),
        .mem_wb_rd       (mem_wb_rd),
        .mem_wb_reg_we   (mem_wb_reg_we),
        .mem_wb_writeback(wb_data),
        .id_ex_rs1       (id_ex_rs1),
        .id_ex_rs2       (id_ex_rs2),
        .stall           (stall_w),
        .if_id_flush     (if_id_flush_w),
        .id_ex_flush     (id_ex_flush_w),
        .forward_a       (forward_a),
        .forward_b       (forward_b)
    );

    logic [31:0] pc_normal_next;

    assign pc_normal_next = (stall_w || ex_muldiv_stall) ? pc :
                            mem_take_trap                 ? mem_pc_redirect :
                            ex_mem_branch_taken           ? ex_mem_branch_target :
                                                            (pc + 32'd4);

    assign branch_flush = ex_mem_branch_taken || mem_take_trap;

    assign pc_next = pc_normal_next;

    // debug

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
            5'b01110: alu_op_name = "MUL";
            5'b01111: alu_op_name = "MULH";
            5'b10000: alu_op_name = "MULHSU";
            5'b10001: alu_op_name = "MULHU";
            5'b10010: alu_op_name = "DIV";
            5'b10011: alu_op_name = "DIVU";
            5'b10100: alu_op_name = "REM";
            5'b10101: alu_op_name = "REMU";
            default:  alu_op_name = "???";
        endcase
    endfunction

    integer cycle_cnt = 0;

    always_ff @(posedge clk) begin
        if (!reset && uart_cs_bus && uart_we_bus && uart_addr_bus[3:2] == 2'b00)
            $write("%c", uart_wdata_bus[7:0]);
    end

    always @(posedge clk) begin
        cycle_cnt++;
        $display("");
        $display("==============================================================");
        $display(" CYCLE %0d", cycle_cnt);
        $display("==============================================================");
        $display(" IF   PC=0x%08h  instr=0x%08h", pc, if_instr);
        $display(" ID   PC=0x%08h  instr=0x%08h  rs1=x%0d rs2=x%0d rd=x%0d",
                 if_id_pc, if_id_instr, id_rs1, id_rs2, id_rd);
        $display(" EX   PC=0x%08h  op=%s  A=0x%08h B=0x%08h result=0x%08h  fwd_a=%0b fwd_b=%0b",
                 id_ex_pc, alu_op_name(ex_alu_control),
                 ex_alu_a, ex_alu_b, ex_alu_out, forward_a, forward_b);
        $display(" MEM  PC=0x%08h  alu=0x%08h  mem_we=%b mem_re=%b  branch_taken=%b",
                 ex_mem_pc, ex_mem_alu_out, ex_mem_mem_we, ex_mem_mem_re, ex_mem_branch_taken);
        $display(" WB   PC=0x%08h  rd=x%0d  data=0x%08h  we=%b",
                 mem_wb_pc, wb_rd, wb_data, wb_reg_we);
        $display(" HAZARD  stall=%b  if_id_flush=%b  id_ex_flush=%b  branch_flush=%b  muldiv_stall=%b",
                 stall_w, if_id_flush_w, id_ex_flush_w, branch_flush, ex_muldiv_stall);
        if (mem_take_trap)
            $display(" TRAP/IRQ  take_trap=1  cause=0x%08h  redirect=0x%08h",
                     mem_mcause_out, mem_pc_redirect);
        $display(" REGS  x1=%0d  x2=%0d  x3=%0d", rf_u.regs[1], rf_u.regs[2], rf_u.regs[3]);
        $display("==============================================================");
    end

endmodule