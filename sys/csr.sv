module csr (
    input  logic        clk,
    input  logic        we,
    input  logic [11:0] csr_addr,
    input  logic [31:0] csr_wdata,
    output logic [31:0] csr_rdata,

    // trap connections
    input  logic [31:0] trap_mepc,
    input  logic [31:0] trap_mcause,
    input  logic        trap_write
);

    /* verilator lint_off CASEINCOMPLETE */

    logic [31:0] mstatus;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mcause;

    initial begin
        mtvec   = 32'h00000100;
        mstatus = 32'h00000000;
    end

    always_comb begin
        case (csr_addr)
            12'h300: csr_rdata = mstatus;
            12'h305: csr_rdata = mtvec;
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            default: csr_rdata = 32'd0;
        endcase
    end

    always_ff @(posedge clk) begin

        if (we) begin
            case (csr_addr)
                12'h300: mstatus <= csr_wdata;
                12'h305: mtvec   <= csr_wdata;
                12'h341: mepc    <= csr_wdata;
                12'h342: mcause  <= csr_wdata;
            endcase
        end

        if (trap_write) begin
            mepc   <= trap_mepc;
            mcause <= trap_mcause;
        end
    end

endmodule
