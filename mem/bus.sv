module bus (
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        we,
    input  logic        re,

    output logic [31:0] rdata,

    output logic        dmem_we,
    output logic        dmem_re,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,   

    output logic        uart_we
);

always_comb begin
    dmem_we    = 0;
    dmem_re    = 0;
    uart_we    = 0;

    dmem_addr  = addr;
    dmem_wdata = wdata;

    rdata = 32'b0;

    if (addr < 32'h00001000) begin
        dmem_we = we;
        dmem_re = re;
        rdata   = dmem_rdata;
    end
    else if (addr == 32'h10000000) begin
        uart_we = we;
    end
end

endmodule