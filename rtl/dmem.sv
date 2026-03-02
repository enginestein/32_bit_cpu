    module dmem (
        input  logic        clk,
        input  logic        we,
        input  logic        re,
        input  logic [31:0] addr,
        input  logic [31:0] wd,
        input  logic [2:0]  funct3,
        output logic [31:0] rd,
        output logic misaligned
    );

    /* verilator lint_off EOFNEWLINE */
    /* verilator lint_off CASEINCOMPLETE */
    /* verilator lint_off PROCASSINIT */
    /* verilator lint_off BLKSEQ */

        parameter RAM_SIZE = 4096;
        logic [7:0] mem [0:RAM_SIZE-1];

    // ── Misalignment Check ────────────────────────────────────────────────────────

    always_comb begin
        misaligned = 1'b0;
        if (we || re) begin
            case (funct3)
                3'b001, 3'b101: if (addr[0] != 1'b0)   misaligned = 1'b1; // SH/LH/LHU
                3'b010:         if (addr[1:0] != 2'b00) misaligned = 1'b1; // SW/LW
                default: misaligned = 1'b0;
            endcase
        end
    end

    // ── Store ─────────────────────────────────────────────────────────────────────

    always_ff @(posedge clk) begin
        if (we) begin
            case (funct3)
                3'b000: begin // SB — 1 byte
                    mem[addr] <= wd[7:0];
                end

                3'b001: begin // SH — 2 bytes
                    mem[addr]     <= wd[7:0];
                    mem[addr + 1] <= wd[15:8];
                end

                3'b010: begin // SW — 4 bytes
                    mem[addr]     <= wd[7:0];
                    mem[addr + 1] <= wd[15:8];
                    mem[addr + 2] <= wd[23:16];
                    mem[addr + 3] <= wd[31:24];
                end
            endcase
        end
    end

    // ── Load ──────────────────────────────────────────────────────────────────────

    always_comb begin
        rd = 32'b0;
        if (re) begin
            case (funct3)
                3'b000: rd = {{24{mem[addr][7]}},   mem[addr]};                                          // LB
                3'b001: rd = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]};                             // LH
                3'b010: rd = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};                         // LW
                3'b100: rd = {24'b0,                mem[addr]};                                          // LBU
                3'b101: rd = {16'b0,                mem[addr+1], mem[addr]};                             // LHU
            endcase
        end
    end

    endmodule
