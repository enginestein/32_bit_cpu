module csr (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,
    input  logic [11:0] csr_addr,
    input  logic [31:0] csr_wdata,
    output logic [31:0] csr_rdata,
    output logic        mstatus_mie,
    output logic [31:0] mtvec_out,
    input  logic [31:0] trap_mepc,
    input  logic [31:0] trap_mcause,
    input  logic        trap_write,
    input  logic [31:0] mip_hw
);

    logic [31:0] mstatus;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mcause;
    logic [31:0] mie_reg;
    logic [31:0] mip_reg;

    assign mstatus_mie = mstatus[3];
    assign mtvec_out   = mtvec;

    always_comb begin
        case (csr_addr)
            12'h300: csr_rdata = mstatus;
            12'h304: csr_rdata = mie_reg;
            12'h305: csr_rdata = mtvec;
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h344: csr_rdata = mip_reg;
            default: csr_rdata = 32'd0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            mstatus <= 32'h00000000;
            mtvec   <= 32'h00000100;
            mie_reg <= 32'h00000000;
            mepc    <= 32'h00000000;
            mcause  <= 32'h00000000;
        end else if (trap_write) begin
            mepc    <= trap_mepc;
            mcause  <= trap_mcause;
            mstatus <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
        end else if (we) begin
            case (csr_addr)
                12'h300: mstatus <= csr_wdata;
                12'h304: mie_reg <= csr_wdata;
                12'h305: mtvec   <= csr_wdata;
                12'h341: mepc    <= csr_wdata;
                12'h342: mcause  <= csr_wdata;
                default: ; 
            endcase
        end
        mip_reg <= mip_hw;
    end

endmodule